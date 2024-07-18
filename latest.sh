sudo apt install figlet -y
clear

figlet "WELCOME"
echo "DSI Panel v1.0.0-beta"
echo "Powered By - DSI LLC"
echo "www.dsillc.cloud/dsi-panel/docs"
echo "------------------------------------------"

# Ask domain name from user and store into master_domain variable
read -p "Enter the domain name: " master_domain
export master_domain=$(echo $master_domain | tr '[:upper:]' '[:lower:]')

if [ -z "$master_domain" ] || ! [[ "$master_domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    figlet "Error: Invalid Domain Name"
    exit 1
fi

figlet "System Update"
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


figlet "Installing DSI Panel Core"
# Download zip file from server and store into /var/dsi-panel/*
wget -O /var/dsi-panel.zip https://securedownloads.dsillc.cloud/    
unzip /var/dsi-panel.zip -d /var/dsipanel
rm /var/dsi-panel.zip 

# Setting up the domain 

# extract username from master_domain and store it into username variable
username=$(echo $master_domain | cut -d '.' -f 1)
document_root="/home/$username/$domain"
 
# Create user
username=$1
password="Kanai@123"
userdir="/home/$username"

# Create user
sudo useradd -m -d $userdir -s /bin/bash $username

# Set password for user
echo "$username:$password" | sudo chpasswd

# Set ownership and permissions for user directory
sudo chown -R $username:$username $userdir
sudo chmod 700 $userdir

# Update SSH configuration to allow the new user
sudo sh -c "echo 'AllowUsers $username' >> /etc/ssh/sshd_config"

# Restart SSH service
sudo systemctl restart ssh

echo "SSH User $username created with password $password"


# SFTP add complete
figlet "SFTP Added ✅"

#  Add Domain process -----------------
ipAddress=$(curl -s -X GET https://checkip.amazonaws.com --max-time 10)

# Add entry to the local hosts file
echo "$ipAddress $domain" | sudo tee -a /etc/hosts >/dev/null

# Create the directory structure
sudo mkdir -p "$document_root"
sudo chown -R www-data:www-data "$document_root"

# Set permissions for directories
find "$document_root" -type d -exec chmod 755 {} \;

# Set permissions for files
find "$document_root" -type f -exec chmod 644 {} \;

# Create a simple HTML file for testing
cp /var/dsipanel/welcome.html $document_root/index.html

# Create Apache virtual host configuration
sudo tee "/etc/apache2/sites-available/$domain.conf" >/dev/null <<EOL

<VirtualHost *:80>
    ServerAdmin webmaster@$domain
    ServerName $domain

    Redirect permanent /cpanel http://server2.dsillc.online
    Redirect permanent /fmanager http://server2.dsillc.online/filemanager

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
	RewriteMap hosts-deny "txt:/var/dsipanel/default/blockedip"
	RewriteCond "${hosts-deny:%{REMOTE_ADDR}|NOT-FOUND}" "!=NOT-FOUND" [OR]
	RewriteCond "${hosts-deny:%{REMOTE_HOST}|NOT-FOUND}" "!=NOT-FOUND"
	RewriteRule .* -[F]

    ErrorLog $document_root/error.log
    # CustomLog /home/$username/.access.log combined
</VirtualHost>

<VirtualHost *:443>
    ServerAdmin webmaster@$domain
    ServerName $domain

    Redirect permanent /cpanel https://server2.dsillc.online
    Redirect permanent /fmanager https://server2.dsillc.online/filemanager

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
	RewriteMap hosts-deny "txt:/var/dsipanel/default/blockedip"
	RewriteCond "${hosts-deny:%{REMOTE_ADDR}|NOT-FOUND}" "!=NOT-FOUND" [OR]
	RewriteCond "${hosts-deny:%{REMOTE_HOST}|NOT-FOUND}" "!=NOT-FOUND"
	RewriteRule .* -[F]

    ErrorLog $document_root/error.log
    # CustomLog /home/$username/.access.log combined
</VirtualHost>

EOL

sudo chown -R www-data:www-data $document_root

sudo chmod +x /home/$username
#sudo chmod +x /home/$username/public_html

# Enable the site
sudo a2ensite "$domain.conf"

# Reload Apache to apply changes
sudo systemctl reload apache2

echo "Domain $domain added successfully. DocumentRoot: $document_root"

figlet "Thanks !" 
echo "www.dsillc.cloud/dsi-panel"
