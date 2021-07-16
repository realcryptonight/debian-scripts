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

# Clean up.
rm /deploy.txt
rm setup.sh