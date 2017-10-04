#! /bin/sh
#
# author: Nathan Baker (unr34l-dud3)
# desc:

echo grab scripts
sudo wget https://raw.githubusercontent.com/dpndbl/server-setup/master/bin/apt-update.sh -O /usr/local/bin/apt-update
sudo wget https://raw.githubusercontent.com/dpndbl/server-setup/master/bin/ratom.sh -O /usr/local/bin/ratom
sudo wget https://raw.githubusercontent.com/dpndbl/server-setup/master/bin/la.sh -O /usr/local/bin/la

echo allow executing scripts
sudo chmod +x /usr/local/bin/apt-update
sudo chmod +x /usr/local/bin/ratom
sudo chmod +x /usr/local/bin/la

echo install my personal must haves
sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt-get install htop bwm-ng sudo wget apt-show-versions libpam-systemd dbus screen git -y


echo vagrant setup
# /*=================================
# =            VARIABLES            =
# =================================*/
INSTALL_NGINX_INSTEAD=0

reboot_webserver_helper() {

    if [ $INSTALL_NGINX_INSTEAD != 1 ]; then
        sudo service apache2 restart
    fi

    if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
        sudo systemctl restart php7.0-fpm
        sudo systemctl restart nginx
    fi

    echo 'Rebooting your webserver'
}


# /*=========================================
# =            CORE / BASE STUFF            =
# =========================================*/
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install -y build-essential
sudo apt-get install -y tcl
sudo apt-get install -y software-properties-common
sudo apt-get -y install vim
sudo apt-get -y install git


# /*======================================
# =            INSTALL APACHE            =
# ======================================*/
if [ $INSTALL_NGINX_INSTEAD != 1 ]; then

    # Install the package
    sudo apt-get -y install apache2

    # Remove "html" and add public
    mv /var/www/html /var/www/public

    # Clean VHOST with full permissions
    MY_WEB_CONFIG='<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/public
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        <Directory "/var/www/public">
            Options Indexes FollowSymLinks
            AllowOverride all
            Require all granted
        </Directory>
    </VirtualHost>'
    echo "$MY_WEB_CONFIG" | sudo tee /etc/apache2/sites-available/000-default.conf

    # Squash annoying FQDN warning
    echo "ServerName scotchbox" | sudo tee /etc/apache2/conf-available/servername.conf
    sudo a2enconf servername

    # Enabled missing h5bp modules (https://github.com/h5bp/server-configs-apache)
    sudo a2enmod expires
    sudo a2enmod headers
    sudo a2enmod include
    sudo a2enmod rewrite

    sudo service apache2 restart

fi


# /*=====================================
# =            INSTALL NGINX            =
# =====================================*/
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then

    # Install Nginx
    sudo apt-get -y install nginx
    sudo systemctl enable nginx

    # Remove "html" and add public
    mv /var/www/html /var/www/public

    # Make sure your web server knows you did this...
    MY_WEB_CONFIG='server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/public;
        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
            try_files $uri $uri/ =404;
        }
    }'
    echo "$MY_WEB_CONFIG" | sudo tee /etc/nginx/sites-available/default

    sudo systemctl restart nginx

fi


# /*===================================
# =            INSTALL PHP            =
# ===================================*/
sudo apt-get -y install php

# Make PHP and Apache friends
if [ $INSTALL_NGINX_INSTEAD != 1 ]; then

    sudo apt-get -y install libapache2-mod-php

    # Add index.php to readable file types
    MAKE_PHP_PRIORITY='<IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
    </IfModule>'
    echo "$MAKE_PHP_PRIORITY" | sudo tee /etc/apache2/mods-enabled/dir.conf

    sudo service apache2 restart

fi

# Make PHP and NGINX friends
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then

    # FPM STUFF
    sudo apt-get -y install php-fpm
    sudo systemctl enable php7.0-fpm
    sudo systemctl start php7.0-fpm

    # Fix path FPM setting
    echo 'cgi.fix_pathinfo = 0' | sudo tee -a /etc/php/7.0/fpm/conf.d/user.ini
    sudo systemctl restart php7.0-fpm

    # Add index.php to readable file types and enable PHP FPM since PHP alone won't work
    MY_WEB_CONFIG='server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/public;
        index index.php index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
            try_files $uri $uri/ =404;
        }

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        }

        location ~ /\.ht {
            deny all;
        }
    }'
    echo "$MY_WEB_CONFIG" | sudo tee /etc/nginx/sites-available/default

    sudo systemctl restart nginx

fi


# /*===================================
# =            PHP MODULES            =
# ===================================*/

# Base Stuff
sudo apt-get -y install php-common
sudo apt-get -y install php-all-dev

# Common Useful Stuff
sudo apt-get -y install php-bcmath
sudo apt-get -y install php-bz2
sudo apt-get -y install php-cgi
sudo apt-get -y install php-cli
sudo apt-get -y install php-fpm
sudo apt-get -y install php-imap
sudo apt-get -y install php-intl
sudo apt-get -y install php-json
sudo apt-get -y install php-mbstring
sudo apt-get -y install php-mcrypt
sudo apt-get -y install php-odbc
sudo apt-get -y install php-pear
sudo apt-get -y install php-pspell
sudo apt-get -y install php-tidy
sudo apt-get -y install php-xmlrpc
sudo apt-get -y install php-zip

# CURL
sudo apt-get -y install curl
sudo apt-get -y install php-curl


# /*===========================================
# =            CUSTOM PHP SETTINGS            =
# ===========================================*/
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
    PHP_USER_INI_PATH=/etc/php/7.0/fpm/conf.d/user.ini
else
    PHP_USER_INI_PATH=/etc/php/7.0/apache2/conf.d/user.ini
fi

echo 'display_startup_errors = On' | sudo tee -a $PHP_USER_INI_PATH
echo 'display_errors = On' | sudo tee -a $PHP_USER_INI_PATH
echo 'error_reporting = E_ALL' | sudo tee -a $PHP_USER_INI_PATH
echo 'short_open_tag = On' | sudo tee -a $PHP_USER_INI_PATH
reboot_webserver_helper

# Disable PHP Zend OPcache
echo 'opache.enable = 0' | sudo tee -a $PHP_USER_INI_PATH

# Absolutely Force Zend OPcache off...
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
    sudo sed -i s,\;opcache.enable=0,opcache.enable=0,g /etc/php/7.0/fpm/php.ini
else
    sudo sed -i s,\;opcache.enable=0,opcache.enable=0,g /etc/php/7.0/apache2/php.ini
fi
reboot_webserver_helper


# /*================================
# =            PHP UNIT            =
# ================================*/
sudo wget https://phar.phpunit.de/phpunit-6.1.phar
sudo chmod +x phpunit-6.1.phar
sudo mv phpunit-6.1.phar /usr/local/bin/phpunit
reboot_webserver_helper


# /*=============================
# =            MYSQL            =
# =============================*/
sudo apt-get -y install mariadb
sudo apt-get -y install php-mysql
reboot_webserver_helper


# /*================================
# =            COMPOSER            =
# ================================*/
EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")
php composer-setup.php --quiet
rm composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod 755 /usr/local/bin/composer


# /*=============================
# =            REDIS            =
# =============================*/
sudo apt-get -y install redis-server
sudo apt-get -y install php-redis
reboot_webserver_helper


echo done
