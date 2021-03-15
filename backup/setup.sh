#!/bin/bash

# Check if all args are given
if [ -z "$1" ]
then
	echo "Invalid arguments. Use: ./setup.sh <deployment server address> <is VMware VM yes|no> <backup domain> <use certbot for ssl yes|no> <backup disk (Optional)>"
    exit 1
else
    echo $1 > /deploy.txt
fi

if [ -z "$3" ]
then
	echo "Invalid arguments. Use: ./setup.sh <deployment server address> <is VMware VM yes|no> <backup domain> <use certbot for ssl yes|no> <backup disk (Optional)>"
    exit 1
else
	echo ''
fi

if [ -z "$5" ]
then
	adddisk=0
else
	adddisk=1
fi

# check if adddisk = 1
if [[ "$adddisk" == 1 ]]
then
	(echo n; echo ""; echo ""; echo ""; echo ""; echo w; echo q) | fdisk $(echo $5)
	mkfs.ext4 $5
	mkdir /backups
	mount $5 /backups
	echo "${5} /backups ext4 defaults 1 2" >> /etc/fstab
else
	echo ''
fi

# Get the deploy domain.
dpdomain=`cat /deploy.txt`

case $4 in
	[yY][eE][sS]|[yY])
		echo ''
	;;
	[nN][oO]|[nN])
		echo ''
	;;
	*)
		echo "Invalid arguments. Use: ./setup.sh <deployment server address> <is VMware VM yes|no> <backup domain> <use certbot for ssl yes|no> <backup disk (Optional)>"
		exit 1
	;;
esac

case $2 in
	[yY][eE][sS]|[yY])
		# Install the default settings for the VMware VM server.
		wget -O vmware-settings.sh https://$dpdomain/debian/reuse-scripts/vmware/scripts/vmware-settings.sh
		chmod 777 vmware-settings.sh
		./vmware-settings.sh
		# Install and setup the vsFTPd server.
		wget -O setup-vsftpd.sh https://$dpdomain/debian/reuse-scripts/standard/scripts/setup-vsftpd.sh
		chmod 777 setup-vsftpd.sh
		./setup-vsftpd.sh $3 $4
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
		./setup-vsftpd.sh $3 $4
	;;
	*)
		echo "Invalid arguments. Use: ./setup.sh <deployment server address> <is VMware VM yes|no> <backup domain> <use certbot for ssl yes|no> <backup disk (Optional)>"
		exit 1
	;;
esac

# Add the 10-sysinfo for the backup server.
wget -O 10-sysinfo https://$dpdomain/debian/backup/10-sysinfo
mv 10-sysinfo /etc/update-motd.d/
chmod 777 /etc/update-motd.d/*

case $4 in
	[yY][eE][sS]|[yY])
		echo "All done"
	;;
	[nN][oO]|[nN])
		echo "We are almost done. You only need to add the SSL Cetificate and start vsFTPd"
		echo "Go to /etc/certs/$3/ and add the following files:"
		echo "The full chain as 'fullchain.pem' and th private key as 'privkey.pem'"
		echo "After that type: 'systemctl start vsftpd'"
	;;
	*)
		echo "We are almost done. You only need to add the SSL Cetificate and start vsFTPd"
		echo "Go to /etc/certs/$3/ and add the following files:"
		echo "The full chain as 'fullchain.pem' and th private key as 'privkey.pem'"
		echo "After that type: 'systemctl start vsftpd'"
	;;
esac

# Clean up.
rm setup.sh
rm /deploy.txt