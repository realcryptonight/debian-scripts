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
		# Since it is a VMware VM server we need to add a new backup disk.
		diskinfo=`fdisk -l | grep Disk`
		printf "${diskinfo}"
		read -p "Where is the backup disk located? " disk
		(echo n; echo ""; echo ""; echo ""; echo ""; echo w; echo y; echo q) | fdisk $(echo $disk)
		mkfs.ext4 $disk
		mkdir /backups
		mount $disk /backups
		echo "${disk} /backups ext4 defaults 1 2" >> /etc/fstab
		# Install the default settings for the VMware VM server.
		wget -O standard-settings.sh https://$dpdomain/debian/reuse-scripts/vmware/scripts/vmware-settings.sh
		chmod 777 vmware-settings.sh
		./vmware-settings.sh
		# Install and setup the vsFTPd server.
		wget -O setup-vsftpd.sh https://$dpdomain/debian/reuse-scripts/standard/scripts/setup-vsftpd.sh
		chmod 777 setup-vsftpd.sh
		./setup-vsftpd.sh
	;;
	[nN][oO]|[nN])
		# Install the default settings for the server.
		wget -O standard-settings.sh https://$dpdomain/debian/reuse-scripts/standard/scripts/standard-settings.sh
		chmod 777 standard-settings.sh
		./standard-settings.sh
		# Create the location that on the VMware VM an new disk would be.
		mkdir /backups
		# Install and setup the vsFTPd server.
		wget -O setup-vsftpd.sh https://$dpdomain/debian/reuse-scripts/standard/scripts/setup-vsftpd.sh
		chmod 777 setup-vsftpd.sh
		./setup-vsftpd.sh
	;;
	*)
		echo "Invalid input..."
		exit 1
	;;
esac

# Add the 10-sysinfo for the backup server.
wget -O 10-sysinfo https://$dpdomain/debian/backup/10-sysinfo
mv 10-sysinfo /etc/update-motd.d/
chmod 777 /etc/update-motd.d/*

# Clean up.
rm setup.sh
rm /deploy.txt