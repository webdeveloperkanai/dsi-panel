sudo apt install figlet -y
clear

figlet "WELCOME"
echo "DSI Panel v1.0.0-beta"
echo "Powered By - DSI LLC"
echo "www.dsillc.cloud/dsi-panel/docs"
echo "------------------------------------------"

sudo apt update 
echo "system update checked!"

sudo apt upgrade -y 
echo "system has been updated successfully!"

figlet "SSH"
# Install open ssh ::) 
sudo apt install openssh-server openssh-client -y
# restart openssh 
sudo systemctl restart ssh

echo "ssh has been configured successfully!"

figlet "apache2"
echo "tryning to install apache server"

# installing apache 2
sudo apt install apache2 -y

# allow apache to firewall 
sudo ufw allow in "Apache"

# installing mysql-server
sudo apt install mysql-server -y

# install neseccery extentions of mysql 
sudo apt install php libapache2-mod-php php-mysql -y


# restart apache2 
sudo systemctl restart apache2


# install phpmyadmin 
sudo apt install phpmyadmin -y

# install more extensions
sudo apt install php-mbstring php-zip php-gd php-json php-curl -y


# enable mbstring
sudo phpenmod mbstring

# enable phpmyadmin to apache 
config_content="
Alias /dsi-database /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
    Options SymLinksIfOwnerMatch
    DirectoryIndex index.php

    <IfModule mod_php.c>
        <FilesMatch ".+\.php$">
            SetHandler application/x-httpd-php
        </FilesMatch>
    </IfModule>

    AllowOverride All
</Directory>

# Disallow web access to directories that don't need it
<Directory /usr/share/phpmyadmin/templates>
    Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/libraries>
    Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/setup/lib>
    Require all denied
</Directory>    
"

# Write the content to phpmyadmin.conf
echo "$config_content" | sudo tee /etc/apache2/sites-available/phpmyadmin.conf > /dev/null


# create shortcut of phpmyadmin 
sudo ln -s /etc/apache2/sites-available/phpmyadmin.conf /etc/apache2/sites-enabled/

# restart apache2
sudo systemctl restart apache2

figlet "php versions"
sudo apt install software-properties-common -y
# add repo 
sudo add-apt-repository ppa:ondrej/php
sudo apt update -y

figlet "php 7.3"
sudo apt install php7.3 php7.3-fpm libapache2-mod-php7.3 libapache2-mod-fcgid -y

figlet "php 7.4"
sudo apt install php7.4 php7.4-fpm libapache2-mod-php7.4 libapache2-mod-fcgid -y
a2enmod proxy_fcgi setenvif
sudo a2enmod proxy_fcgi setenvif
sudo systemctl restart apache2

figlet "php 8.2"
sudo apt install php8.2 php8.2-fpm libapache2-mod-php8.2 libapache2-mod-fcgid -y

figlet "php 8.3"
sudo apt install php8.3 php8.3-fpm libapache2-mod-php8.3 libapache2-mod-fcgid -y

sudo apt install php7.4-mysql -y

# install let's encrypt 
figlet "SSL"
sudo apt install certbot python3-certbot-apache -y 
#sudo certbot --apache -d tele.devsecit.com

figlet "Thanks !" 
echo "www.dsillc.cloud/dsi-panel"
