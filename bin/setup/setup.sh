#!/bin/bash
#
# This is a setup shell script to install the necessary packages and setup

home_git_repo="https://github.com/TopHatCroat/home"
user=""

IS_LINUX=0
IS_MACOS=0

if [[ $(uname -s) == "Linux" ]]; then
	IS_LINUX=1
elif [[ $(uname -s) == "Darwin" ]]; then
	IS_MACOS=1
fi;

echo $IS_LINUX
echo $IS_MACOS

if [ $(id -u) -ne 0 ]; then
  echo "Must be run as root."
  exit
fi

check_package_exists() {
  	pkg=$1

  	sudo -u "$user" bash -c "which $pkg > /dev/null 2> /dev/null"
	  if [ $? -eq 0 ]; then
  		return
  	fi

  	false
}

install_package() {
	pkg=$1

	if check_package_exists "$pkg"; then
      echo "Package $pkg exists. Skipping..."
      return 0
  fi

	if [ $IS_LINUX = 1 ]; then
		case "$ID" in
			arch|antergos|manjaro)
				echo "Installing $pkg using pacman..."
				error_output=$(pacman -S --noconfirm "$pkg" 2>&1 >/dev/null)
				;;

			ubuntu)
				echo "Installing $pkg using apt-get..."
				error_output=$(apt-get --assume-yes install "$pkg" 2>&1 >/dev/null)
				;;

			*)
				echo "Unsupported OS!"
				exit 1

		esac

	fi
	
	if [ $IS_MACOS = 1 ]; then
		echo "Installing $pkg using brew..."
		which brew > /dev/null 2> /dev/null

		if [ $? -eq 1 ]; then
			echo "brew missing. Installing..."
			sudo -u $user NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		fi

		error_output=$(sudo -u $user brew install $pkg 2>&1 >/dev/null)

	fi


	if test -z error_output; then
		echo $error_output
		return 1
	else
		echo "Package $pkg installed successfully."
	fi;

	return 0
}

init_home_git_repo() {
  # run the rest of the script as specified user
  sudo -i -u "$user" /bin/bash << EOF
cd ~
if [ ! -d .homegit ]; then
  git --work-tree=$HOME --git-dir=$HOME/.homegit init
  git --work-tree=$HOME --git-dir=$HOME/.homegit remote add origin $home_git_repo
  git --work-tree=$HOME --git-dir=$HOME/.homegit fetch
  git --work-tree=$HOME --git-dir=$HOME/.homegit reset --hard origin/master
  git --work-tree=$HOME --git-dir=$HOME/.homegit submodule update --init
else
  echo ".homegit folder exists in $(pwd). Skipping cloning..."
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

EOF
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

if [ -z $user ]; then
	echo "Argument user is required."
	exit 1
fi

id -u $user > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "User does not exits."
	exit 1
fi

## Package installation preparation

if [ -f "/etc/os-release" ]; then
	# Sources env variables with information about Linux distro like $ID
	source /etc/os-release

	echo "Setting up for $NAME..."

	if [ "$ID" = "ubuntu" ]; then
		apt-get update
	fi
else
	echo "Setting up for MacOS..."
fi

packages=(sudo git zsh vim go pyenv curl)

if [ $IS_LINUX = 1 ]; then
	packages+=(xsel xclip)
fi

if [ $IS_MACOS = 1 ]; then
	packages+=(gpg)
fi

## Package installation

for i in "${packages[@]}"; do

	install_package "$i"
	if [ $? -ne 0 ]; then
		echo "Error occured while installing $i."
		exit 1
	fi

done

if ! check_package_exists "rvm"; then
  echo "Installing rvm..."

  if [ $IS_LINUX = 1 ]; then
    sudo -u "$user" bash -c "gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"
  else
    sudo -u "$user" bash -c "gpg --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"
  fi

  sudo -u "$user" bash -c 'curl -sSL https://get.rvm.io | bash -s stable'
fi

## Other setup

if [ $IS_LINUX = 1 ]; then

	# Set inotify to a reasonable value
	if [ "$ID" = "arch" ] || [ "$ID" = "antergos" ] || [ "$ID" = "manjaro" ] ; then
		echo fs.inotify.max_user_watches=524288 | tee /etc/sysctl.d/40-max-user-watches.conf && sysctl --system
	else
		echo fs.inotify.max_user_watches=524288 | tee -a /etc/sysctl.conf && sysctl -p
	fi

	chsh "$user" -s $(which zsh)

fi

if [ $IS_MACOS = 1 ]; then
	if [ ! -f "/Library/Keyboard Layouts/Croatian-US.icns" ]; then
		echo "Missing Croatian-US-Mac layout. Downloading..."
		sudo -u $user /bin/bash -c "curl -LJO https://github.com/kost/Croatian-US-mac/raw/master/Croatian-US.icns"
		sudo -u $user /bin/bash -c "curl -LJO https://github.com/kost/Croatian-US-mac/raw/master/Croatian-US.keylayout"
		mv Croatian-US.icns "/Library/Keyboard Layouts"
		mv Croatian-US.keylayout "/Library/Keyboard Layouts"
		echo "Done."
		echo "Go to System Preferences -> Keyboard -> Input Sources and select Croatian US"
		echo ""
	fi
fi

init_home_git_repo

echo "Setup done. Log out and back in to change shell"
echo "Have fun!"
