#!/bin/bash

# Get the deploy domain.
dpdomain=`cat /deploy.txt`

# Get the files from the deploy server.
wget -O authorized_keys https://$dpdomain/debian/reuse-scripts/standard/keys/authorized_keys
wget -O 00-header https://$dpdomain/debian/reuse-scripts/standard/banners/00-header
wget -O 10-sysinfo https://$dpdomain/debian/reuse-scripts/standard/banners/10-sysinfo
wget -O 10-uname https://$dpdomain/debian/reuse-scripts/standard/banners/10-uname
wget -O 90-footer https://$dpdomain/debian/reuse-scripts/standard/banners/90-footer

# Setup SSH keys authentication.
mkdir .ssh
chmod 700 .ssh
mv authorized_keys .ssh/
chmod 600 .ssh/authorized_keys

# Remove default motd and replace it with an usefull one.
rm /etc/motd
mv 00-header /etc/update-motd.d/
mv 10-sysinfo /etc/update-motd.d/
mv 10-uname /etc/update-motd.d/
mv 90-footer /etc/update-motd.d/
chmod 777 /etc/update-motd.d/*

# Update the server if needed and setup the SSH server.
apt update
apt -y upgrade
apt -y install figlet vim zip unzip openssh-server
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
service sshd restart

# Clean up.
rm standard-settings.sh