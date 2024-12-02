#!/bin/bash

### TRINITYCORE INSTALL SCRIPT
### TESTED WITH DEBIAN ONLY

. /root/WOTLKTrinityInstaller/configs/root-config
. /root/WOTLKTrinityInstaller/configs/backup-config
. /root/WOTLKTrinityInstaller/configs/auth-config
. /root/WOTLKTrinityInstaller/configs/realm-dev-config

### LETS START
echo "## SCRIPT STARTING...."
echo "## !!!! IF YOU ARE USING REMOTE DB SETUP REQIREMENTS BEFORE !!!!"
export DEBIAN_FRONTEND=noninteractive


if [ "$1" = "" ]; then
## Option List
echo "## No option selected, see list below"
echo ""
echo "- [all] : Run Full Script"
echo ""
echo "- [1] : Install TrinityCore Requirements"
echo "- [2] : Install and Setup MySQL"
echo "- [3] : Create Remote MySQL user"
echo "- [4] : Setup Firewall"
echo "- [5] : Setup Linux Users"
echo "- [6] : Install Fail2Ban"
echo "- [7] : Show Command List"
echo ""
echo "TIP : Use the example 'mail test.example' command to send test mail"
echo ""

else


if [ "$1" = "all" ] || [ "$1" = "1" ]; then
## [1]
# Installing Trinity requirements
echo "Installing Trinity requirements"
apt-get update
apt-get install git clang cmake make gcc gdb g++ libmysqlclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev libboost-all-dev p7zip ncftp --assume-yes
update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100
update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang 100
fi


if [ "$1" = "all" ] || [ "$1" = "2" ]; then
## [2]
# Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
echo "mysql-server mysql-server/root_password password $ROOT_PASS" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $ROOT_PASS" | sudo debconf-set-selections
apt-get -y install mysql-server
# sudo /bin/sh -c 'echo "skip-grant-tables" >> /etc/mysql/mysql.conf.d/mysqld.cnf'
sudo /bin/sh -c 'echo "skip-networking" >> /etc/mysql/mysql.conf.d/mysqld.cnf'
sed -i 's/max_allowed_packet/#max_allowed_packet/g' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo /bin/sh -c 'echo "max_allowed_packet	= 128M" >> /etc/mysql/mysql.conf.d/mysqld.cnf'
sudo /bin/sh -c 'echo 'sql_mode=""' >> /etc/mysql/mysql.conf.d/mysqld.cnf'
service mysql restart
mysql -u root << EOF
use mysql;
update user set user='$ROOT_USER' where user='root';
ALTER USER '$ROOT_USER'@'localhost' IDENTIFIED BY '$ROOT_PASS';
flush privileges;
quit
EOF
sed -i 's/skip-grant-tables/#skip-grant-tables/g' /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i 's/skip-networking/#skip-networking/g' /etc/mysql/mysql.conf.d/mysqld.cnf
if [ $REMOTE_DB_SETUP == "true" ]; then
    sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
fi
service mysql restart
fi


if [ "$1" = "all" ] || [ "$1" = "3" ]; then
## [3]
## Setup MySQL
echo "Setting up MySQL Users"
mysql -u $ROOT_USER -p$ROOT_PASS -D mysql -e "ALTER USER '$ROOT_USER'@'localhost' IDENTIFIED BY '$ROOT_PASS';"
## Remote DB User Setup
if [ $REMOTE_DB_SETUP == "true" ]; then
	mysql -u $ROOT_USER -p$ROOT_PASS -e "GRANT USAGE ON *.* TO '$REMOTE_DB_USER'@'$REMOTE_DB_HOST' IDENTIFIED BY '$REMOTE_DB_PASS' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;"
	mysql -u $ROOT_USER -p$ROOT_PASS -e "GRANT ALL PRIVILEGES ON *.* TO '$REMOTE_DB_USER'@'$REMOTE_DB_HOST' WITH GRANT OPTION;"
fi
mysql -u $ROOT_USER -p$ROOT_PASS -e "FLUSH PRIVILEGES;"
fi


if [ "$1" = "all" ] || [ "$1" = "4" ]; then
## [4]
## Run Firewall Scripts
echo "Setting up Firewall Stuff"
# SSH port
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
# MySQL
iptables -A INPUT -p tcp --dport 3306 -j ACCEPT
if [ $SETUP_DEV_WORLD == "true" ]; then
    # Worldserver
    iptables -A INPUT -p tcp --dport $SETUP_DEV_REALM_PORT -j ACCEPT
fi
if [ $SETUP_AUTH == "true" ]; then
	# Authserver port
	iptables -A INPUT -p tcp --dport 3724 -j ACCEPT
fi
fi


if [ "$1" = "all" ] || [ "$1" = "5" ]; then
## [5]
## Setup User
echo "Setting up Linux user"
if [ $SETUP_DEV_WORLD == "true" ]; then
	sudo useradd -m -p $SETUP_DEV_REALM_PASS -s /bin/bash $SETUP_DEV_REALM_USER
fi
if [ $SETUP_AUTH == "true" ]; then
	sudo useradd -m -p $SETUP_AUTH_PASS -s /bin/bash $SETUP_AUTH_USER
fi
fi


if [ "$1" = "all" ] || [ "$1" = "6" ]; then
## [6]
## Install Fail2Ban
echo "Installing Fail2Ban..."
sudo apt install -y fail2ban

# Enable Fail2Ban to start on boot
echo "Enabling Fail2Ban to start on boot..."
sudo systemctl enable fail2ban

# Start Fail2Ban service
echo "Starting Fail2Ban service..."
sudo systemctl start fail2ban

# Basic configuration (optional)
echo "Creating a local configuration file..."
if [ ! -f /etc/fail2ban/jail.local ]; then
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    echo "[DEFAULT]" | sudo tee -a /etc/fail2ban/jail.local
    echo "bantime  = 1h" | sudo tee -a /etc/fail2ban/jail.local
    echo "findtime  = 10m" | sudo tee -a /etc/fail2ban/jail.local
    echo "maxretry = 3" | sudo tee -a /etc/fail2ban/jail.local
    echo "" | sudo tee -a /etc/fail2ban/jail.local
    echo "[sshd]" | sudo tee -a /etc/fail2ban/jail.local
    echo "enabled = true" | sudo tee -a /etc/fail2ban/jail.local
fi

# Restart Fail2Ban to apply changes
echo "Restarting Fail2Ban service..."
sudo systemctl restart fail2ban

# Status of Fail2Ban
echo "Checking the status of Fail2Ban..."
sudo systemctl status fail2ban

echo "Fail2Ban installation completed!"
fi

if [ "$1" = "all" ] || [ "$1" = "7" ]; then
## [7]
## FINISH SCRIPT
echo "Root install Completed!"
echo ""
echo "####  FOR AUTHSERVER INSTALL ####"
echo "run 'cd /root/WOTLKTrinityInstaller/scripts/Setup/ && ./Auth-Install.sh' on the $SETUP_AUTH_USER user"
echo ""
echo "####  FOR DEV REALM INSTALL ####"
echo "run 'cd /root/WOTLKTrinityInstaller/scripts/Setup/ && ./Realm-Dev-Install.sh' on the $SETUP_DEV_REALM_USER user"
fi
fi
