#!/bin/bash

echo "What should be the username of the FTP user?"
read username

adduser $username
mkdir /backups/$username
mkdir /backups/$username/ftp
chown nobody:nogroup /backups/$username/ftp
chmod a-w /backups/$username/ftp
mkdir /backups/$username/ftp/files
chown $username:$username /backups/$username/ftp/files
echo $username >> /etc/vsftpd.userlist
usermod $username -s /bin/ftponly