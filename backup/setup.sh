#!/bin/bash

# Check if all args are given
if [ -z "$1" ]
then
	echo "Invalid arguments. Use: ./setup.sh <deployment server address> <is VMware VM yes|no> <backup domain> <backup disk (Optional)>"
    exit 1
else
    echo $1 > /deploy.txt
fi

if [ -z "$3" ]
then
	echo "Invalid arguments. Use: ./setup.sh <deployment server address> <is VMware VM yes|no> <backup domain> <backup disk (Optional)>"
    exit 1
else
	echo ''
fi

if [ -z "$4" ]
then
	adddisk=0
else
	adddisk=1
fi

# check if adddisk = 1
if [[ "$adddisk" == 1 ]]
then
	(echo n; echo ""; echo ""; echo ""; echo ""; echo w; echo y; echo q) | fdisk $(echo $4)
	mkfs.ext4 $4
	mkdir /backups
	mount $4 /backups
	echo "${4} /backups ext4 defaults 1 2" >> /etc/fstab
else
	echo ''
fi

# Get the deploy domain.
dpdomain=`cat /deploy.txt`

echo "dpserver: $1"
echo "VMware: $2"
echo "Backup domain: $3"
echo "disk: $4"

case $2 in
	[yY][eE][sS]|[yY])
		# Install the default settings for the VMware VM server.
		wget -O vmware-settings.sh https://$dpdomain/debian/reuse-scripts/vmware/scripts/vmware-settings.sh
		chmod 777 vmware-settings.sh
		./vmware-settings.sh
		# Install and setup the vsFTPd server.
		wget -O setup-vsftpd.sh https://$dpdomain/debian/reuse-scripts/standard/scripts/setup-vsftpd.sh
		chmod 777 setup-vsftpd.sh
		./setup-vsftpd.sh $3
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
		./setup-vsftpd.sh $3
	;;
	*)
		echo "Invalid arguments. Use: ./setup.sh <deployment server address> <is VMware VM yes|no> <backup domain> <backup disk (Optional)>"
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