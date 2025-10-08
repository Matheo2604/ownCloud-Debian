#!/bin/bash

# This script installs and configures ownCloud with Apache, MariaDB, and PHP on a Debian-based system.

# Clear the terminal and prompt the user for the ownCloud password
clear
while true; do
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
wget https://download.owncloud.com/server/stable/owncloud-complete-latest.tar.bz2
tar -xjf owncloud-complete-latest.tar.bz2
cp -r owncloud /var/www
apt update
apt-get -y install owncloud-complete-files

# Configure Apache
cat > /etc/apache2/sites-available/owncloud.conf << 'EOL'
Alias / "/var/www/owncloud/"
ErrorLog ${APACHE_LOG_DIR}/owncloud_error.log
CustomLog ${APACHE_LOG_DIR}/owncloud_access.log combined
<Directory /var/www/owncloud/>
  Options +FollowSymlinks
  AllowOverride All

 <IfModule mod_dav.c>
  Dav off
 </IfModule>

 SetEnv HOME /var/www/owncloud
 SetEnv HTTP_HOME /var/www/owncloud

</Directory>
EOL

a2ensite owncloud.conf
a2dissite 000-default.conf
a2enmod rewrite mime unique_id
apachectl -t
systemctl restart apache2

# Set up MariaDB
mysql --password=$owncloud_password --user=root --host=localhost << eof
  create database ownclouddb;
  grant all privileges on ownclouddb.* to root@localhost identified by "$owncloud_password";
  flush privileges;
  quit
eof

# Install ownCloud
cd /var/www/owncloud
sudo -u www-data php occ maintenance:install \
   --database "mysql" \
   --database-name "ownclouddb" \
   --database-user "root"\
   --database-pass "$owncloud_password" \
   --admin-user "admin" \
   --admin-pass "$owncloud_password"

# Reminder to update ownCloud configuration
echo "Don't forget to change the accessible network in this file: /var/www/owncloud/config/config.php/"
