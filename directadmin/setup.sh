#!/bin/bash

# Check if all args are given
if [ -z "$1" ]
then
	echo "Invalid arguments. Use: ./setup.sh <deployment server address> <is VMware VM yes|no>"
    exit 1
else
    echo $1 > /deploy.txt
fi

# Get the deploy domain.
dpdomain=`cat /deploy.txt`

case $2 in
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
apt -y install sshpass gcc g++ make flex bison openssl libssl-dev perl perl-base perl-modules libperl-dev libperl4-corelibs-perl libwww-perl libaio1 libaio-dev zlib1g zlib1g-dev libcap-dev cron bzip2 zip automake autoconf libtool cmake pkg-config python libdb-dev libsasl2-dev libncurses5 libncurses5-dev libsystemd-dev bind9 dnsutils quota patch logrotate rsyslog libc6-dev libexpat1-dev libcrypt-openssl-rsa-perl libnuma-dev libnuma1

# Download and run DirectAdmin install script.
wget -O install.sh https://www.directadmin.com/setup.sh
chmod 755 install.sh
./install.sh auto

# Install Curl via custombuilds.
cd /usr/local/directadmin/custombuild
sed -i "s/curl=no/curl=yes/g" options.conf
./build curl

# Install the updated script fot SSH.
cd /usr/local/directadmin/scripts/custom/
wget -O ssh_script.zip https://github.com/poralix/directadmin-sftp-backups/archive/refs/heads/master.zip
unzip ssh_script.zip
cd directadmin-sftp-backups-master/
mv ftp_*.php ./../
cd ..
rm -rf directadmin-sftp-backups-master/
rm ssh_script.zip

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
# And setup DKIM.
echo "mail_sni=1" >> /usr/local/directadmin/conf/directadmin.conf
service directadmin restart
cd /usr/local/directadmin
./directadmin set dkim 2
cd /usr/local/directadmin/custombuild
./build clean
./build update
./build set eximconf yes
./build set eximconf_release 4.5
./build set dovecot_conf yes
./build exim_conf
./build dovecot_conf
./build exim
./build eximconf
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