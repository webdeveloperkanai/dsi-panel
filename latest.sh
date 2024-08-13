    #!/bin/bash

    # Ensure figlet is installed
    if ! command -v figlet &> /dev/null
    then
        echo "figlet could not be found, installing..."
        apt update && apt install -y figlet
    fi
    if ! command -v unzip &> /dev/null
    then
        echo "unzip/zip could not be found, installing..."
        apt install unzip
    fi

    figlet "WELCOME"
    echo "DSI Panel v1.0.0-beta"
    echo "Powered By - DSI LLC"
    echo "www.dsillc.cloud/dsi-panel/docs"
    echo "------------------------------------------"

    # Ask domain name from user and store into master_domain variable
    echo "Enter the domain name:"
    read -r domain

    domain=$(echo "$domain" | tr '[:upper:]' '[:lower:]')

    if [ -z "$domain" ] || ! [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        figlet "Error: Invalid Domain Name"
        exit 1
    fi

figlet "System Update"
apt update 
echo "System update checked!"

apt upgrade -y 
echo "system has been updated successfully!"

figlet "SSH"
# Install open ssh ::) 
apt install openssh-server openssh-client -y
# restart openssh 
systemctl restart ssh

echo "ssh has been configured successfully!"

figlet "apache2"
echo "tryning to install apache server"

# installing apache 2
apt install apache2 -y

# allow apache to firewall 
ufw allow in "Apache"

# installing mysql-server
apt install mysql-server -y

# install neseccery extentions of mysql 
apt install php libapache2-mod-php php-mysql -y


# restart apache2 
systemctl restart apache2


# install phpmyadmin 
apt install phpmyadmin -y

# install more extensions
apt install php-mbstring php-zip php-gd php-json php-curl -y


# enable mbstring
phpenmod mbstring

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
echo "$config_content" | tee /etc/apache2/sites-available/phpmyadmin.conf > /dev/null


# create shortcut of phpmyadmin 
ln -s /etc/apache2/sites-available/phpmyadmin.conf /etc/apache2/sites-enabled/

# restart apache2
systemctl restart apache2

figlet "php versions"
apt install software-properties-common -y
# add repo 
add-apt-repository ppa:ondrej/php
apt update -y

figlet "php 7.3"
apt install php7.3 php7.3-fpm libapache2-mod-php7.3 libapache2-mod-fcgid -y

figlet "php 7.4"
apt install php7.4 php7.4-fpm libapache2-mod-php7.4 libapache2-mod-fcgid -y
a2enmod proxy_fcgi setenvif
a2enmod proxy_fcgi setenvif
systemctl restart apache2

figlet "php 8.2"
apt install php8.2 php8.2-fpm libapache2-mod-php8.2 libapache2-mod-fcgid -y

figlet "php 8.3"
apt install php8.3 php8.3-fpm libapache2-mod-php8.3 libapache2-mod-fcgid -y

apt install php7.4-mysql -y

# install let's encrypt 
figlet "SSL"
apt install certbot python3-certbot-apache -y 
#certbot --apache -d tele.devsecit.com


figlet "Installing DSI Panel Core"
# Download zip file from server and store into /var/dsi-panel/*
wget -O /var/dsi-panel.zip https://securedownloads.dsillc.cloud/var-dsi-panel.zip 
chmod +x /var/dsi-panel.zip
unzip /var/dsi-panel.zip -d /var/dsipanel
rm /var/dsi-panel.zip 

rm /var/www/html/index.html
cp /var/dsipanel/welcome.html /var/www/html/index.html

# Enable url rewrite
a2enmod rewrite

# Setting up the domain 

# extract username from master_domain and store it into username variable
username=$(echo "$domain" | cut -d '.' -f 1)
document_root="/home/$username/$domain"
 
# Create user
username=$1
password="Kanai@123"
userdir="/home/$username"

# Create user
useradd -m -d $userdir -s /bin/bash $username

# Set password for user
echo "$username:$password" | chpasswd

# Set ownership and permissions for user directory
chown -R $username:$username $userdir
chmod 700 $userdir

# Update SSH configuration to allow the new user
sh -c "echo 'AllowUsers $username' >> /etc/ssh/sshd_config"

# Restart SSH service
systemctl restart ssh

echo "SSH User $username created with password $password"


# SFTP add complete
figlet "SFTP Added"

#  Add Domain process -----------------
ipAddress=$(curl -s -X GET https://checkip.amazonaws.com --max-time 10)

# Add entry to the local hosts file
echo "$ipAddress $domain" | tee -a /etc/hosts >/dev/null

# Create the directory structure
mkdir -p "$document_root"
chown -R www-data:www-data "$document_root"

# Set permissions for directories
find "$document_root" -type d -exec chmod 755 {} \;

# Set permissions for files
find "$document_root" -type f -exec chmod 644 {} \;

# Create a simple HTML file for testing
cp /var/dsipanel/welcome.html $document_root/index.html

# Create Apache virtual host configuration
tee "/etc/apache2/sites-available/$domain.conf" >/dev/null <<EOL

<VirtualHost *:80>
    ServerAdmin webmaster@$domain
    ServerName $domain

    Redirect permanent /cpanel http://server.dsillc.cloud
    Redirect permanent /fmanager http://files.dsillc.cloud

    DocumentRoot $document_root

     <FilesMatch \.php$>
        SetHandler "proxy:unix:/var/run/php/php7.4-fpm.sock|fcgi://localhost/"
    </FilesMatch>

    <Directory $document_root>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

	<FilesMatch "^\.">
		Require all denied
	</FilesMatch>

	<IfModule mod_ratelimit.c>
        	SetOutputFilter RATE_LIMIT
        	SetEnv rate-limit 100
	</IfModule>

	RewriteEngine On
	#RewriteMap hosts-deny "txt:/var/dsipanel/default/blockedip"
	#RewriteCond "${hosts-deny:%{REMOTE_ADDR}|NOT-FOUND}" "!=NOT-FOUND" [OR]
	#RewriteCond "${hosts-deny:%{REMOTE_HOST}|NOT-FOUND}" "!=NOT-FOUND"
	#RewriteRule .* -[F]

    ErrorLog $document_root/error.log
    CustomLog /home/$username/.access.log combined
</VirtualHost>

<VirtualHost *:443>
    ServerAdmin webmaster@$domain
    ServerName $domain

    Redirect permanent /cpanel https://server.dsillc.cloud
    Redirect permanent /fmanager https://files.dsillc.cloud


    DocumentRoot $document_root

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/var/run/php/php7.4-fpm.sock|fcgi://localhost/"
    </FilesMatch>


    <Directory $document_root>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

        <FilesMatch "^\.">
                Require all denied
        </FilesMatch>

        <IfModule mod_ratelimit.c>
                SetOutputFilter RATE_LIMIT
                SetEnv rate-limit 100
        </IfModule>

	RewriteEngine On
	#RewriteMap hosts-deny "txt:/var/dsipanel/default/blockedip"
	#RewriteCond "${hosts-deny:%{REMOTE_ADDR}|NOT-FOUND}" "!=NOT-FOUND" [OR]
	#RewriteCond "${hosts-deny:%{REMOTE_HOST}|NOT-FOUND}" "!=NOT-FOUND"
	#RewriteRule .* -[F]

    ErrorLog $document_root/error.log
    CustomLog /home/$username/.access.log combined
</VirtualHost>

EOL

chown -R www-data:www-data $document_root

chmod +x /home/$username
#chmod +x /home/$username/public_html

# Enable the site
a2ensite "$domain.conf"

# Reload Apache to apply changes
systemctl reload apache2

echo "Domain $domain added successfully. DocumentRoot: $document_root"

figlet "Thanks !"
echo "SET NEW PASSWORD OF phpmyadmin"
echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'new_password';"
echo "www.dsillc.cloud/dsi-panel" << EOL
