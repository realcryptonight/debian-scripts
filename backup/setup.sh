#!/bin/bash

# Check if all args are given
if [ -z "$1" ]
then
	echo "Invalid arguments. Use: ./setup.sh <deployment server address> <backup disk (Optional)>"
    exit 1
else
    echo $1 > /deploy.txt
fi

if [ -z "$2" ]
then
	adddisk=0
else
	adddisk=1
fi

if [[ "$adddisk" == 1 ]]
then
	(echo n; echo ""; echo ""; echo ""; echo ""; echo w; echo q) | fdisk $(echo $2)
	mkfs.ext4 $2
	mkdir /backups
	mount $2 /backups
	echo "${2} /backups ext4 defaults 1 2" >> /etc/fstab
else
	echo ''
fi

# Get the deploy domain.
dpdomain=`cat /deploy.txt`

# Install the default settings for the server.
wget -O standard-settings.sh https://$dpdomain/debian/reuse-scripts/scripts/standard-settings.sh
chmod 777 standard-settings.sh
./standard-settings.sh

wget https://$dpdomain/debian/reuse-scripts/scripts/add_ssh_user.sh
chmod 700 add_ssh_user.sh
chown root:root /backups

groupadd sftpgroup
sed -i 's/Subsystem/#Subsystem/g' /etc/ssh/sshd_config
echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config
echo "   Match Group sftpgroup" >> /etc/ssh/sshd_config
echo "   ChrootDirectory /backups" >> /etc/ssh/sshd_config
echo "   ForceCommand internal-sftp" >> /etc/ssh/sshd_config
echo "   X11Forwarding no" >> /etc/ssh/sshd_config
echo "   AllowTcpForwarding no" >> /etc/ssh/sshd_config
service sshd restart

# Add the 10-sysinfo for the backup server.
wget -O 10-sysinfo https://$dpdomain/debian/backup/10-sysinfo
mv 10-sysinfo /etc/update-motd.d/
chmod 777 /etc/update-motd.d/*

# Clean up.
rm setup.sh
rm /deploy.txt