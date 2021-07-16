#!/bin/bash

if [ -z "$1" ]
then
	echo "Invalid arguments. Use: ./setup.sh <deployment server address>"
    exit 1
else
    echo $1 > /deploy.txt
fi

# Get the deploy domain.
dpdomain=`cat /deploy.txt`

# Install the default settings for the server.
wget -O standard-settings.sh https://$dpdomain/debian/reuse-scripts/scripts/standard-settings.sh
chmod 777 standard-settings.sh
./standard-settings.sh

apt -y install screen apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

apt-key fingerprint 0EBFCD88
read -r -p "Is the key from docker? [Y/n] " input

case $input in
	[yY][eE][sS]|[yY])
		echo "All good. We will continue."
	;;
	[nN][oO]|[nN])
		echo "Something went wrong. Please try again later."
		exit 1
	;;
	*)
		echo "Invalid input..."
		exit 1
	;;
esac

apt update
apt -y install docker-ce docker-ce-cli containerd.io
apt -y install docker-compose
docker run hello-world

read -r -p "Did docker start? [Y/n] " input

case $input in
	[yY][eE][sS]|[yY])
		echo "All good. We will continue."
	;;
	[nN][oO]|[nN])
		echo "Something went wrong. Please try again later."
		exit 1
	;;
	*)
		echo "Invalid input..."
		exit 1
	;;
esac
curl -s https://laravel.build/example-app | bash
cd example-app
chmod -R 775 storage bootstrap/cache
cd ..

# Clean up.
rm setup.sh
rm /deploy.txt

reboot