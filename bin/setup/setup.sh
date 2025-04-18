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
	if [ -d .homegit ]; then
	  	echo ".homegit folder exists in $(pwd). Skipping cloning..."
		return
	fi

	if [ $IS_LINUX = 1 ]; then
		# run the rest of the script as specified user
		sudo -i -u "$user" /bin/bash << EOF
cd ~
git --work-tree=$HOME --git-dir=$HOME/.homegit init
git --work-tree=$HOME --git-dir=$HOME/.homegit remote add origin $home_git_repo
git --work-tree=$HOME --git-dir=$HOME/.homegit fetch
git --work-tree=$HOME --git-dir=$HOME/.homegit reset --hard origin/master
git --work-tree=$HOME --git-dir=$HOME/.homegit submodule update --init

EOF 
	else
		/bin/bash << EOF
cd ~
git --work-tree=$HOME --git-dir=$HOME/.homegit init
git --work-tree=$HOME --git-dir=$HOME/.homegit remote add origin $home_git_repo
git --work-tree=$HOME --git-dir=$HOME/.homegit fetch
git --work-tree=$HOME --git-dir=$HOME/.homegit reset --hard origin/master
git --work-tree=$HOME --git-dir=$HOME/.homegit submodule update --init

EOF
	fi
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

if [ IS_LINUX = 1 ]; then
	if [ $(id -u) -ne 0 ]; then
		echo "Must be run as root."
		exit
	fi

	# Linux installs run as root so we need to know who is the user to install apps to
	if [ -z $user ]; then
		echo "Argument user is required."
		exit 1

		id -u $user > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "User does not exits."
			exit 1
		fi
	fi

	if [ -f "/etc/os-release" ]; then
		# Sources env variables with information about Linux distro like $ID
		source /etc/os-release

		echo "Setting up for $NAME..."

		if [ "$ID" = "ubuntu" ]; then
			apt-get update
		fi
	fi
else
	echo "Setting up for MacOS..."
fi


# Setting up packages
packages=(sudo git zsh vim go pyenv curl asdf docker docker-compose volta jabba)

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


if [ -z $JAVA_HOME ]; then
	echo "Setting up JDK 17"
	
	jabba install openjdk@17
	jabba use openjdk@17
	jabba alias default openjdk@17.0
fi

if ! check_package_exists "node"; then
	echo "Installing node & yarn"
	volta install node
	volta install yarn
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
	if [ ! -f "/Library/Keyboard Layouts/Croatian-US.icns" ]; then
		echo "Missing Croatian-US-Mac layout. Downloading..."
		sudo -u $user /bin/bash -c "curl -LJO https://github.com/kost/Croatian-US-mac/raw/master/Croatian-US.icns"
		sudo -u $user /bin/bash -c "curl -LJO https://github.com/kost/Croatian-US-mac/raw/master/Croatian-US.keylayout"
		mv Croatian-US.icns "/Library/Keyboard Layouts"
		mv Croatian-US.keylayout "/Library/Keyboard Layouts"
		echo "Done."
		echo "Restart your system then go to System Preferences -> Keyboard -> Input Sources and select Croatian US"
		echo ""
	fi
fi

init_home_git_repo

echo "Setup done. Log out and back in to change shell"
echo "Have fun!"
