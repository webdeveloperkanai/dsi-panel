echo "DSI Panel - Uninstall wizard"

sudo systemctl stop apache2.service
sudo systemctl stop apachee2
sudo service apache2 stop

sudo apt-get remove apache2 -y

sudo apt remove apache2*
sudo apt-get purge apache2 apache2-utils apache2.2-bin apache2-common -y
sudo apt-get purge apache2 apache2-utils apache2-bin apache2.2-common -y

sudo rm -rf /etc/apache2  
sudo apt-get purge php*.* -y

sudo systemctl stop mysql
sudo apt-get purge mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-* -y
sudo rm -rf /etc/mysql /var/lib/mysql
sudo apt-get remove --purge mysql*
sudo apt-get remove --purge mysql-server mysql-client mysql-common libapache2-mod-php software-properties-common -y 


sudo apt-get remove --purge php7.3 php7.3-fpm libapache2-mod-php7.3 libapache2-mod-fcgid php7.4 php7.4-fpm libapache2-mod-php7.4 libapache2-mod-fcgid  php8.2 php8.2-fpm libapache2-mod-php8.2 libapache2-mod-fcgid  php8.3 php8.3-fpm libapache2-mod-php8.3 libapache2-mod-fcgid -y

sudo apt-get autoremove
sudo apt-get autoclean
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/mysql
sudo apt-get autoremove
sudo apt-get autoclean
sudo rm -rf /var/www/html
sudo apt-get autoremove phpmyadmin
sudo apt-get purge phpmyadmin
sudo rm -vfR /usr/share/phpmyadmin

sudo apt-get autoremove
sudo apt-get autoclean
