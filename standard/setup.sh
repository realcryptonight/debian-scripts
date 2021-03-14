#!/bin/bash

# Ask user for deploy domain.
echo "What is the deploy domain? example: deploy.danielmarkink.nl"
read deploydomain
echo $deploydomain > /deploy.txt

# Get the deploy domain.
dpdomain=`cat /deploy.txt`

echo "Is this a VMware VM?"
read input
case $input in
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
		echo "Invalid input..."
		exit 1
	;;
esac

# Clean up.
rm /deploy.txt
rm setup.sh