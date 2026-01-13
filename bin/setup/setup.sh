#!/bin/bash
#
# This is a setup shell script to install the necessary packages and setup

home_git_repo="git@github.com:TopHatCroat/home.git"
user=""

IS_LINUX=0
IS_MACOS=0

if [[ $(uname -s) == "Linux" ]]; then
	IS_LINUX=1
elif [[ $(uname -s) == "Darwin" ]]; then
	IS_MACOS=1
fi;

check_package_exists() {
  	check_pkg=$1

	if [ $IS_LINUX = 1 ]; then
		sudo -u "$user" bash -c "which $check_pkg > /dev/null 2> /dev/null"
	else
		command -v $check_pkg &>/dev/null;
	fi

	if [ $? -eq 0 ]; then
		return
	fi

  	false
}

install_package() {
	pckg=$1

	if check_package_exists "$pckg"; then
		echo "Package $pckg exists. Skipping..."
		return 0
  	fi

	if [ $IS_LINUX = 1 ]; then
		case "$ID" in
			arch|antergos|manjaro)
				echo "Installing $pckg using pacman..."
				error_output=$(pacman -S --noconfirm "$pckg" 2>&1 >/dev/null)
				;;

			ubuntu)
				echo "Installing $pckg using apt-get..."
				error_output=$(apt-get --assume-yes install "$pckg" 2>&1 >/dev/null)
				;;

			*)
				echo "Unsupported OS!"
				exit 1

		esac

	fi
	
	if [ $IS_MACOS = 1 ]; then
		echo "Installing $pckg using brew..."

		if ! check_package_exists "brew"; then
			echo "brew missing. Installing..."
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		fi

		error_output=$(brew install $pckg 2>&1 >/dev/null)
	fi

	if test -z error_output; then
		echo $error_output
		return 1
	else
		echo "Package $pckg installed successfully."
	fi;

	return 0
}

init_home_git_repo() {

	if [ -n "$user" ]; then
		target_home=$(eval echo "~$user")
	else
		target_home="$HOME"
	fi

	if [ -d "$target_home/.homegit" ]; then
		echo ".homegit folder exists in $target_home. Skipping cloning..."
		return
	fi

	echo "Initializing home git repo in $target_home"

	/bin/bash -c \
		"cd '$target_home' && \
		git --work-tree='$target_home' --git-dir='$target_home/.homegit' init && \
		git --work-tree='$target_home' --git-dir='$target_home/.homegit' remote add origin $home_git_repo && \
		git --work-tree='$target_home' --git-dir='$target_home/.homegit' fetch && \
		git --work-tree='$target_home' --git-dir='$target_home/.homegit' reset --hard origin/main && \
		git --work-tree='$target_home' --git-dir='$target_home/.homegit' submodule update --init"
}

print_help() {
	echo "Bootstrap script for new enviroments. Must be run as root"
	echo ""
	echo "Usage: setup.sh -u <name> [arguments]"
	echo ""
	echo "Arguments:"
	echo "  -u    Name of user to setup the enviroment for. It must exist."
	echo "  -h    Print this"
}

while getopts "hu:" OPTION
do
	case $OPTION in
		h)
			print_help
			exit
			;;
		u)
			user=$OPTARG
			;;
		\?)
			print_help
			exit
			;;
	esac
done

# Enforce user rules depending on platform:
# - Linux: -u <user> is required and script must be run as root
# - macOS: default to current user if -u not provided
if [ "$IS_LINUX" = "1" ]; then
	if [ $(id -u) -ne 0 ]; then
		echo "Must be run as root."
		exit 1
	fi

	if [ -z "$user" ]; then
		echo "Argument -u <user> is required on Linux."
		exit 1
	fi

	id -u "$user" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "User does not exist: $user"
		exit 1
	fi

	if [ -f "/etc/os-release" ]; then
		source /etc/os-release
		echo "Setting up for $NAME..."
		if [ "$ID" = "ubuntu" ]; then
			apt-get update
		fi
	fi
else
	if [ -z "$user" ]; then
		user="$(whoami)"
	fi
	echo "Setting up for MacOS... (user: $user)"
fi

user_home=$(eval echo "~$user")

# Setting up packages
packages=(sudo git zsh vim curl docker docker-compose alacritty)

if [ $IS_LINUX = 1 ]; then
	packages+=(xsel xclip)
fi

if [ $IS_MACOS = 1 ]; then
	packages+=(gpg docker-desktop)
fi

## Package installation
for i in "${packages[@]}"; do

	install_package "$i"
	if [ $? -ne 0 ]; then
		echo "Error occured while installing $i."
		exit 1
	fi
done

if ! check_package_exists "mise"; then
	echo "Installing mise..."
	curl https://mise.run | sh
fi

if [ -z $JAVA_HOME ]; then
	echo "Setting up JDK 17"
	mise use -g java@temurin  
fi

if ! check_package_exists "node"; then
	echo "Installing node & pnpm"
	mise use -g node@lts
	mise use -g pnpm@latest
fi

if ! check_package_exists "bun"; then
	echo "Installing bun"
	mise use -g bun@latest
fi

## Other setup
if [ $IS_LINUX = 1 ]; then

	# Set inotify to a reasonable value
	if [ "$ID" = "arch" ] || [ "$ID" = "antergos" ] || [ "$ID" = "manjaro" ] ; then
		echo fs.inotify.max_user_watches=524288 | tee /etc/sysctl.d/40-max-user-watches.conf && sysctl --system
	else
		echo fs.inotify.max_user_watches=524288 | tee -a /etc/sysctl.conf && sysctl -p
	fi

	# refresh font cache to make fonts in ~/.fonts accessible
	if command -v fs-cache &> /dev/null; then
		echo "Refreshing font cache..."
		fc-cache -fv > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			# Sometimes fc-cache is unavailable, like in some Docker containers
			echo "Unable to refresh font cache. Skipping..."
			exit 1
		fi
	fi

	chsh "$user" -s $(which zsh)

fi

if [ $IS_MACOS = 1 ]; then
	# Install keyboard layouts into the user's ~/Library/Keyboard Layouts
	target_dir="$user_home/Library/Keyboard Layouts"

	if [ ! -d "$target_dir" ]; then
		echo "Creating $target_dir"
		mkdir -p "$target_dir"
		if [ -n "$user" ] && [ "$user" != "$(whoami)" ]; then
			chown "$user" "$target_dir" 2>/dev/null || true
		fi
	fi

	if [ ! -f "$target_dir/Croatian-US.icns" ] || [ ! -f "$target_dir/Croatian-US.keylayout" ]; then
		echo "Missing Croatian-US-Mac layout. Downloading..."
		tmpdir=$(mktemp -d)
		curl -L -o "$tmpdir/Croatian-US.icns" https://raw.githubusercontent.com/kost/Croatian-US-mac/master/Croatian-US.icns
		curl -L -o "$tmpdir/Croatian-US.keylayout" https://raw.githubusercontent.com/kost/Croatian-US-mac/master/Croatian-US.keylayout

		mv -f "$tmpdir/Croatian-US.icns" "$target_dir/"
		mv -f "$tmpdir/Croatian-US.keylayout" "$target_dir/"
		if [ -n "$user" ] && [ "$user" != "$(whoami)" ]; then
			chown "$user":"$user" "$target_dir/Croatian-US.icns" "$target_dir/Croatian-US.keylayout" 2>/dev/null || true
		fi
		rm -rf "$tmpdir"

		echo "Done."
		echo "Log out and back in or go to System Preferences -> Keyboard -> Input Sources and select Croatian US"
		echo ""
	else
		echo "Croatian-US-Mac layout already installed. Skipping..."
	fi
fi

init_home_git_repo

if [ $IS_MACOS = 1 ]; then
	# Install fonts
	cp $user_home/.fonts/* "$user_home/Library/Fonts/"
fi

echo "Setup done. Log out and back in to change shell"
echo "Have fun!"
