#!/bin/bash

# Get the deploy domain.
dpdomain=`cat /deploy.txt`

# Install required software.
apt -y install vsftpd certbot

# Get the needed info from the user.
echo "What should be the username of the first FTP user?"
read username
echo "What is the domain that the FTP server will run on?"
read domain

# Setup the first system user to use vsFTPd
adduser $username
mkdir /backups/$username
mkdir /backups/$username/ftp
chown nobody:nogroup /backups/$username/ftp
chmod a-w /backups/$username/ftp
mkdir /backups/$username/ftp/files
chown $username:$username /backups/$username/ftp/files

# Changing vsFTPD settings.
echo "# Custom settings." >> /etc/vsftpd.conf
sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf
sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/1' /etc/vsftpd.conf
echo "user_sub_token=\$USER" >> /etc/vsftpd.conf
echo "local_root=/backups/\$USER/ftp" >> /etc/vsftpd.conf
echo "pasv_min_port=50000" >> /etc/vsftpd.conf
echo "pasv_max_port=50500" >> /etc/vsftpd.conf
echo "userlist_enable=YES" >> /etc/vsftpd.conf
echo "userlist_file=/etc/vsftpd.userlist" >> /etc/vsftpd.conf
echo "userlist_deny=NO" >> /etc/vsftpd.conf
echo $username > /etc/vsftpd.userlist

# Setup FTP SSL and configure vsFTPd to use it.
certbot certonly --standalone --register-unsafely-without-email --agree-tos --preferred-challenges http -d $domain
echo "renew_hook = systemctl restart vsftpd" >> /etc/letsencrypt/renewal/$domain.conf
sed -i "s/rsa_cert_file=\/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/rsa_cert_file=\/etc\/letsencrypt\/live\/$domain\/fullchain.pem/g" /etc/vsftpd.conf
sed -i "s/rsa_private_key_file=\/etc\/ssl\/private\/ssl-cert-snakeoil.key/rsa_private_key_file=\/etc\/letsencrypt\/live\/$domain\/privkey.pem/g" /etc/vsftpd.conf
sed -i 's/ssl_enable=NO/ssl_enable=YES/g' /etc/vsftpd.conf
echo "implicit_ssl=YES" >> /etc/vsftpd.conf
echo "listen_port=21" >> /etc/vsftpd.conf
echo "force_local_data_ssl=YES" >> /etc/vsftpd.conf
echo "force_local_logins_ssl=YES" >> /etc/vsftpd.conf
systemctl restart vsftpd

# Prevent FTP users from using SSH.
echo '#!/bin/sh' > /bin/ftponly
echo 'echo "This account is blocked from SSH."' >> /bin/ftponly
chmod a+x /bin/ftponly
echo "/bin/ftponly" >> /etc/shells
usermod $username -s /bin/ftponly

# Get the script to add more users later.
wget -O add_ftp_user.sh https://$dpdomain/debian/reuse-scripts/standard/scripts/add_ftp_user.sh
chmod 777 add_ftp_user.sh

# Clean up.
rm setup-vsftpd.sh