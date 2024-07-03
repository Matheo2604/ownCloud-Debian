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
echo -e "Please enter the time interval (in seconds) to wait between each file scan.\n 
         The longer the interval, the smoother the file movement will be, but the shorter\n 
         the interval, the more resource-intensive it will be. "
read -p "(Default is 3 seconds): " time

# Update package lists and install necessary packages
apt-get update
apt-get -y install apache2 mariadb-server sudo


# Add PHP repository and install PHP 7.4 and necessary extensions
apt-get -y install apt-transport-https lsb-release ca-certificates wget
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
apt-get update
apt-get -y install php7.4-{xml,intl,common,json,curl,mbstring,mysql,gd,imagick,zip,opcache} libapache2-mod-php7.4
a2enmod php7.4

# Add ownCloud repository and install ownCloud
echo 'deb https://download.opensuse.org/repositories/isv:/ownCloud:/server:/10/Debian_12/ /' > /etc/apt/sources.list.d/isv:ownCloud:server:10.list
curl -fsSL https://download.opensuse.org/repositories/isv:/ownCloud:/server:/10/Debian_12/Release.key | gpg --dearmor > /etc/apt/trusted.gpg.d/isv_ownCloud_server_10.gpg
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
   --admin-user "root" \
   --admin-pass "$owncloud_password"

# Create a service to scan ownCloud files periodically
cat > /var/www/owncloud/smb.sh << 'EOL'
#!/bin/bash
cd /var/www/owncloud/data
chown -R www-data:www-data .
find . -type d -exec chmod g+rwx {} +
find . -type f -exec chmod g+rw {} +
sudo -u www-data php ./occ files:scan --all
sleep $time
EOL
chmod +x /var/www/owncloud/smb.sh

cat > /etc/systemd/system/ownCloud_smb_scan.service << 'EOL'
[Unit]
Description=Scan OwnCloud files every $time seconds

[Service]
ExecStart=/var/www/owncloud/smb.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOL

systemctl enable ownCloud_smb_scan.service
systemctl start ownCloud_smb_scan.service

# Create script to add new users
cat > /var/www/owncloud/create_user.sh <<EOF
#!/bin/bash

read -p "Enter a username: " user
while true; do
  read -sp "Password to use for smb: " password
  echo -e ''
  read -sp "Repeat the password: " password_verification
  echo -e ''
  if [ "\$password" = "\$password_verification" ]; then
    break
  fi
done

# Now execute the rest of the script with the \$user and \$password variables

curl -X POST -u root:$owncloud_password \
     -d userid=\$user \
     -d password=\$password \
     http://127.0.0.1/ocs/v1.php/cloud/users -H "OCS-APIREQUEST: true"

useradd -m -s /bin/bash \$user
echo \$user:\$password | chpasswd

smbpasswd -a \$user << eof
\$password
\$password
eof

mkdir -p /var/www/owncloud/data/\$user/files

echo "[\$user]
        path = /var/www/owncloud/data/\$user/files
        valid users = \$user
        writable = yes
        browseable = yes
        create mask = 0700" >> /etc/samba/smb.conf

usermod -a -G www-data \$user
systemctl restart smb apache2

EOF

chgrp -R www-data /var/www/owncloud/data && chmod -R g+rwx /var/www/owncloud/data
chmod +x /var/www/owncloud/create_user.sh

# Add alias for user creation script
echo "alias ocu='/var/www/owncloud/create_user.sh'" >> /etc/bash.bashrc

# Reminder to update ownCloud configuration
echo "Don't forget to change the accessible network in this file: /var/www/owncloud/config/config.php/"
