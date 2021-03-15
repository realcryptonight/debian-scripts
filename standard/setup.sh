#!/bin/bash

# Check if all args are given
if [ -z "$0" ]
then
	echo "Invalid arguments. Use: ./setup.sh <deployment server address> <is VMware VM yes|no>"
    exit 1
else
    echo $0 > /deploy.txt
fi

# Get the deploy domain.
dpdomain=`cat /deploy.txt`

case $1 in
	[yY][eE][sS]|[yY])
		# Install the default settings for the VMware VM server.
		wget -O vmware-settings.sh https://$dpdomain/debian/reuse-scripts/vmware/scripts/vmware-settings.sh
		chmod 777 vmware-settings.sh
		./vmware-settings.sh
	;;
	[nN][oO]|[nN])
		# Install the default settings for the server.
		wget -O standard-settings.sh https://$dpdomain/debian/reuse-scripts/standard/scripts/standard-settings.sh
		chmod 777 standard-settings.sh
		./standard-settings.sh
	;;
	*)
		echo "Invalid arguments. Use: ./setup.sh <deployment server address> <is VMware VM yes|no>"
		exit 1
	;;
esac

# Clean up.
rm /deploy.txt
rm setup.sh