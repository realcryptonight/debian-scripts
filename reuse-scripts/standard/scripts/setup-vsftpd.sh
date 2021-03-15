#!/bin/bash

# Get the deploy 1.
dpdomain=`cat /deploy.txt`

case $2 in
	[yY][eE][sS]|[yY])
		apt -y install vsftpd certbot
		systemctl stop vsftpd
		# Setup FTP SSL.
		certbot certonly --standalone --register-unsafely-without-email --agree-tos --preferred-challenges http -d $1
		sed -i "s/rsa_cert_file=\/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/rsa_cert_file=\/etc\/letsencrypt\/live\/$1\/fullchain.pem/g" /etc/vsftpd.conf
		sed -i "s/rsa_private_key_file=\/etc\/ssl\/private\/ssl-cert-snakeoil.key/rsa_private_key_file=\/etc\/letsencrypt\/live\/$1\/privkey.pem/g" /etc/vsftpd.conf
		sed -i 's/ssl_enable=NO/ssl_enable=YES/g' /etc/vsftpd.conf
		echo "renew_hook = systemctl restart vsftpd" >> /etc/letsencrypt/renewal/$1.conf
		systemctl start vsftpd
	;;
	[nN][oO]|[nN])
		apt -y install vsftpd
		systemctl stop vsftpd
		# Setup FTP SSL.
		echo "no" > /hasssl.txt
		mkdir /etc/certs
		mkdir /etc/certs/$1
		chmod 755 /etc/certs/
		chmod 755 /etc/certs/$1/
		sed -i "s/rsa_cert_file=\/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/rsa_cert_file=\/etc\/certs\/$1\/fullchain.pem/g" /etc/vsftpd.conf
		sed -i "s/rsa_private_key_file=\/etc\/ssl\/private\/ssl-cert-snakeoil.key/rsa_private_key_file=\/etc\/certs\/$1\/privkey.pem/g" /etc/vsftpd.conf
		sed -i 's/ssl_enable=NO/ssl_enable=YES/g' /etc/vsftpd.conf
	;;
	*)
		apt -y install vsftpd
		systemctl stop vsftpd
		# Setup FTP SSL.
		echo "no" > /hasssl.txt
		mkdir /etc/certs
		mkdir /etc/certs/$1
		chmod 755 /etc/certs/
		chmod 755 /etc/certs/$1/
		sed -i "s/rsa_cert_file=\/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/rsa_cert_file=\/etc\/certs\/$1\/fullchain.pem/g" /etc/vsftpd.conf
		sed -i "s/rsa_private_key_file=\/etc\/ssl\/private\/ssl-cert-snakeoil.key/rsa_private_key_file=\/etc\/certs\/$1\/privkey.pem/g" /etc/vsftpd.conf
		sed -i 's/ssl_enable=NO/ssl_enable=YES/g' /etc/vsftpd.conf
	;;
esac

# Changing vsFTPD settings.
echo "# Custom settings." >> /etc/vsftpd.conf
sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf
sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/1' /etc/vsftpd.conf
echo "user_sub_token=\$USER" >> /etc/vsftpd.conf
echo "local_root=/backups/\$USER/ftp" >> /etc/vsftpd.conf
echo "pasv_min_port=30000" >> /etc/vsftpd.conf
echo "pasv_max_port=30500" >> /etc/vsftpd.conf
echo "userlist_enable=YES" >> /etc/vsftpd.conf
echo "userlist_file=/etc/vsftpd.userlist" >> /etc/vsftpd.conf
echo "userlist_deny=NO" >> /etc/vsftpd.conf
echo "implicit_ssl=YES" >> /etc/vsftpd.conf
echo "listen_port=990" >> /etc/vsftpd.conf
echo "force_local_data_ssl=YES" >> /etc/vsftpd.conf
echo "force_local_logins_ssl=YES" >> /etc/vsftpd.conf

# Prevent FTP users from using SSH.
echo '#!/bin/sh' > /bin/ftponly
echo 'echo "This account is blocked from SSH."' >> /bin/ftponly
chmod a+x /bin/ftponly
echo "/bin/ftponly" >> /etc/shells

# Get the script to add users.
wget -O add_ftp_user.sh https://$dpdomain/debian/reuse-scripts/standard/scripts/add_ftp_user.sh
chmod 744 add_ftp_user.sh

# Clean up.
rm setup-vsftpd.sh