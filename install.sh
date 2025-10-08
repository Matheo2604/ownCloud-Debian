#!/bin/bash


# This script installs and configures ownCloud with Apache, MariaDB, and PHP7 on a Debian-based system.


# Clear the terminal and prompt the user for the ownCloud password and domain
clear
while true; do
    echo ''
    echo ''
    read -p "Domain or IP used to connect to ownCloud: " domain
    echo ''
    read -sp "Password to use for ownCloud: " owncloud_password
    echo ''
    read -sp "Repeat the password: " owncloud_password_verification
    echo ''
    if [ "$owncloud_password" = "$owncloud_password_verification" ]; then
        break
    fi    
done


# Update package lists and install necessary packages
apt-get update
apt-get -y install apache2 mariadb-server sudo curl gpg


# Add PHP repository and install PHP 7.4 and necessary extensions
apt-get -y install apt-transport-https lsb-release ca-certificates wget
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
apt-get update
apt-get -y install php7.4-{xml,intl,common,json,curl,mbstring,mysql,gd,imagick,zip,opcache} libapache2-mod-php7.4 php7.4


# Add ownCloud repository and install ownCloud
echo 'deb https://download.opensuse.org/repositories/isv:/ownCloud:/server:/10/Debian_12/ /' > /etc/apt/sources.list.d/isv:ownCloud:server:10.list
curl -fsSL https://download.opensuse.org/repositories/isv:/ownCloud:/server:/10/Debian_12/Release.key | gpg --dearmor > /etc/apt/trusted.gpg.d/isv_ownCloud_server_10.gpg
apt update
apt-get -y install owncloud-complete-files


# Configure Apache
cat > /etc/apache2/sites-available/owncloud.conf << 'EOL'
<VirtualHost *:80>
	ServerName {domain}
	Redirect permanent / https://{domain}
</VirtualHost>

<VirtualHost *:443>
	ServerName {domain}

	DocumentRoot /var/www/owncloud
	Alias / "/var/www/owncloud/"

	ErrorLog ${APACHE_LOG_DIR}/owncloud_error.log
	CustomLog ${APACHE_LOG_DIR}/owncloud_access.log combined

	SSLEngine on
	SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
	SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key

	<Directory /var/www/owncloud/>
		Options +FollowSymlinks
		AllowOverride All
		<IfModule mod_dav.c>
			Dav off
		</IfModule>
		SetEnv HOME /var/www/owncloud
		SetEnv HTTP_HOME /var/www/owncloud
	</Directory>
</VirtualHost>
EOL

sed -i "s/{domain}/$domain/g" /etc/apache2/sites-available/owncloud.conf


# Create the selfsigned certificate to have a basic security
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt << EOT
NA
NA
NA
NA
NA
NA
NA
EOT

# Restart apache to take in charge the new configuration
a2enmod ssl
a2ensite owncloud.conf
a2dissite 000-default.conf
a2enmod rewrite mime unique_id
apachectl -t


# Setup MariaDB
mysql --password=$owncloud_password --user=root --host=localhost << eof
  create database ownclouddb;
  grant all privileges on ownclouddb.* to root@localhost identified by "$owncloud_password";
  flush privileges;
  quit
eof


# Setup ownCloud database
cd /var/www/owncloud
sudo -u www-data php occ maintenance:install \
   --database "mysql" \
   --database-name "ownclouddb" \
   --database-user "root"\
   --database-pass "$owncloud_password" \
   --admin-user "admin" \
   --admin-pass "$owncloud_password"
sed -i "/0 => 'localhost',/a\	    1 => '$domain'," /var/www/owncloud/config/config.php


# Setup of basic Firewall rules
apt-get install -y ufw
systemctl enable --now ufw
ufw allow "Apache Full"


# Restart apache take in count the new configuration 
systemctl restart apache2


# Reminder of the username, password and domain
echo ''
echo "The installation is now finish. Enjoy !"
echo "You can now connect to https://$domain"
echo "username: admin"
echo "password: $owncloud_password"
echo ''
exit 0
