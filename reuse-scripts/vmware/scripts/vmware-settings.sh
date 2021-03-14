#!/bin/bash

# Get the deploy domain.
dpdomain=`cat /deploy.txt`

# Get the default script and run it.
wget -O standard-settings.sh https://$dpdomain/debian/reuse-scripts/standard/scripts/standard-settings.sh
chmod 777 standard-settings.sh
./standard-settings.sh

# Install all extra tools needed for VMware.
apt -y install open-vm-tools

# clean up.
rm vmware-settings.sh