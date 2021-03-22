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

# Pre-Install commands.
apt -y install gcc g++ make flex bison openssl libssl-dev perl perl-base perl-modules libperl-dev libperl4-corelibs-perl libwww-perl libaio1 libaio-dev zlib1g zlib1g-dev libcap-dev cron bzip2 zip automake autoconf libtool cmake pkg-config python libdb-dev libsasl2-dev libncurses5 libncurses5-dev libsystemd-dev bind9 dnsutils quota patch logrotate rsyslog libc6-dev libexpat1-dev libcrypt-openssl-rsa-perl libnuma-dev libnuma1

# Download and run DirectAdmin install script.
wget -O install.sh https://www.directadmin.com/setup.sh
chmod 755 install.sh
./install.sh auto

# Install Curl via custombuilds.
cd /usr/local/directadmin/custombuild
sed -i "s/curl=no/curl=yes/g" options.conf
./build curl

# Apply patched scripts for backup with (explicit) FTPS.
cd /usr/local/directadmin/scripts/custom/
wget -O ftp_download.php https://$dpdomain/debian/reuse-scripts/standard/patched/directadmin/ftp_download.php
wget -O ftp_upload.php https://$dpdomain/debian/reuse-scripts/standard/patched/directadmin/ftp_upload.php
wget -O ftp_list.php https://$dpdomain/debian/reuse-scripts/standard/patched/directadmin/ftp_list.php


# Install Let's Encrypt SSL for DirectAdmin Web Interface.
cd /usr/local/directadmin/custombuild
./build rewrite_confs
./build update
./build letsencrypt
. /usr/local/directadmin/scripts/setup.txt
/usr/local/directadmin/scripts/letsencrypt.sh request_single $hostname 4096
/usr/local/directadmin/directadmin set ssl_redirect_host $hostname
service directadmin restart
	
# Allow the mail server to use the SSL from the website.
echo "mail_sni=1" >> /usr/local/directadmin/conf/directadmin.conf
service directadmin restart
cd /usr/local/directadmin/custombuild
./build clean
./build update
./build set eximconf yes
./build set eximconf_release 4.5
./build set dovecot_conf yes
./build exim_conf
./build dovecot_conf
echo "action=rewrite&value=mail_sni" >> /usr/local/directadmin/data/task.queue

# Clean up.
cd /root/
rm install.sh
rm setup.sh
rm /deploy.txt

clear
. /usr/local/directadmin/scripts/setup.txt
echo "Username: $adminname"
echo "Password: $adminpass"
echo "Domain: $hostname"