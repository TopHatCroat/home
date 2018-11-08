#!/bin/bash
#
# This is a setup shell script to install the necessary packages and setup

home_git_repo="https://github.com/TopHatCroat/home"
user=""

if [ $(id -u) -ne 0 ]; then
  echo "Must be run as root."
  exit
fi

install_package() {
	pkg=$1
	which $pkg > /dev/null 2> /dev/null
	if [ $? -eq 0 ]; then
		echo "Package $pkg exists. Skipping..."
		return 0
	fi

	echo "Installing package $pkg..."
	case "$ID" in
		arch|antergos)
			error_output=$(pacman -S --noconfirm $pkg 2>&1 >/dev/null)
			;;

		ubuntu)
			error_output=$(apt-get --assume-yes install $pkg 2>&1 >/dev/null)
			;;

		*)
			echo "Unsupported OS!"
			exit 1

	esac

	if test -z error_output; then
		echo $error_output
		return 1
	fi

	echo "Package $pkg installed successfully."
	return 0
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

# Sources env variables with information about Linux distro like $ID
source /etc/os-release
echo "Setting up for $NAME..."

if [ "$ID" = "ubuntu" ]; then
	apt-get update
fi

packages=(sudo git zsh vim go)
for i in "${packages[@]}"; do

	install_package $i
	if [ $? -ne 0 ]; then
		echo "Error occured while installing $i."
		exit 1
	fi

done

chsh $user -s $(which zsh)
# run the rest of the script as specified user
sudo -i -u $user /bin/bash << EOF

cd ~
if [ ! -d .git ]; then
	git init
	git remote add origin $home_git_repo
	git fetch
	git checkout -t origin/master
else
	echo ".git folder exists in $(pwd). Skipping cloning..."
fi

# refresh font cache to make fonts in ~/.fonts accessible
echo "Refreshing font cache..."
fc-cache -fv > /dev/null 2>&1
if [ $? -ne 0 ]; then
	# Sometimes fc-cache is unavailable, like in some Docker containers
	echo "Unable to refresh font cache. Skipping..."
	exit 1
fi

EOF

echo "Setup done. Log out and back in to change shell"
echo "Have fun!"
