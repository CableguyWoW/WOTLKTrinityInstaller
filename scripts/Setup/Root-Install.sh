#!/bin/bash

### TRINITYCORE INSTALL SCRIPT
### TESTED WITH DEBIAN ONLY

. /WOTLKTrinityInstaller/configs/root-config
. /WOTLKTrinityInstaller/configs/auth-config
. /WOTLKTrinityInstaller/configs/realm-dev-config

### LETS START
echo ""
echo "##########################################################"
echo "## ROOT INSTALL SCRIPT STARTING...."
echo "##########################################################"
echo ""
NUM=0
export DEBIAN_FRONTEND=noninteractive


if [ "$1" = "" ]; then
echo ""
echo "## No option selected, see list below"
echo ""
echo "- [all] : Run Full Script"
echo ""
((NUM++)); echo "- [$NUM] : Randomize Passwords"
((NUM++)); echo "- [$NUM] : Install TrinityCore Requirements"
((NUM++)); echo "- [$NUM] : Install and Setup MySQL"
((NUM++)); echo "- [$NUM] : Create Remote MySQL user"
((NUM++)); echo "- [$NUM] : Setup Firewall"
((NUM++)); echo "- [$NUM] : Setup Linux Users"
((NUM++)); echo "- [$NUM] : Install Fail2Ban"
((NUM++)); echo "- [$NUM] : Show Command List"
echo ""
echo ""


else


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Installing Trinity requirements"
echo "##########################################################"
echo ""
sudo apt update -y
sudo apt-get install git screen clang cmake make gcc g++ libmysqlclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev libboost-all-dev p7zip --assume-yes
update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100
update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang 100
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Install MySQL Server"
echo "##########################################################"
echo ""
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


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM. Setting up MySQL Users"
echo "##########################################################"
echo ""
# Update the password for the ROOT user
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -D mysql -e "ALTER USER '$ROOT_USER'@'localhost' IDENTIFIED BY '$ROOT_PASS';"

# Remote DB User Setup
if [ "$REMOTE_DB_SETUP" == "true" ]; then
    # Create the remote DB user
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE USER '$REMOTE_DB_USER'@'$REMOTE_DB_HOST' IDENTIFIED BY '$REMOTE_DB_PASS';"
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT USAGE ON *.* TO '$REMOTE_DB_USER'@'$REMOTE_DB_HOST' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;"
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT ALL PRIVILEGES ON *.* TO '$REMOTE_DB_USER'@'$REMOTE_DB_HOST' WITH GRANT OPTION;"
    echo "Setup Remote DB Account"
fi

# World Database Setup
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE DATABASE ${REALM_DB_USER}_world DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE DATABASE ${REALM_DB_USER}_character DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
# Create the realm user
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE USER '${REALM_DB_USER}'@'localhost' IDENTIFIED BY '$REALM_DB_PASS';"
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT USAGE ON ${REALM_DB_USER}_world.* TO '${REALM_DB_USER}'@'localhost' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;"
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT USAGE ON ${REALM_DB_USER}_character.* TO '${REALM_DB_USER}'@'localhost' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;"
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT ALL PRIVILEGES ON ${REALM_DB_USER}_world.* TO '${REALM_DB_USER}'@'localhost';"
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT ALL PRIVILEGES ON ${REALM_DB_USER}_character.* TO '${REALM_DB_USER}'@'localhost';"
echo "Setup World DB Account"
# Auth Database Setup
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE DATABASE auth DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
# Create the auth user
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE USER '$AUTH_DB_USER'@'localhost' IDENTIFIED BY '$AUTH_DB_PASS';"
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT USAGE ON auth.* TO '$AUTH_DB_USER'@'localhost' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;"
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT ALL PRIVILEGES ON auth.* TO '$AUTH_DB_USER'@'localhost';"
echo "Setup Auth DB Account"

mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "FLUSH PRIVILEGES;"
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setting up Firewall"
echo "##########################################################"
echo ""
sudo apt-get install ufw --assume-yes
# SSH port
sudo ufw allow 22
if [ "$REMOTE_DB_SETUP" = "true" ]; then
sudo ufw allow 3306
fi
if [ $SETUP_DEV_WORLD == "true" ]; then
    sudo ufw allow $SETUP_REALM_PORT
fi
if [ $SETUP_AUTH == "true" ]; then
    sudo ufw allow 3724
fi
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Linux Users"
echo "##########################################################"
echo ""
if [ $SETUP_DEV_WORLD == "true" ]; then
	sudo useradd -m -p $SETUP_REALM_PASS -s /bin/bash $SETUP_REALM_USER
    if ! sudo grep -q "$SETUP_REALM_USER ALL=(ALL) NOPASSWD: ALL" "/etc/sudoers.d/$SETUP_AUTH_USER"; then
        echo "$SETUP_REALM_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$SETUP_REALM_USER
        echo "Added $SETUP_REALM_USER to sudoers with NOPASSWD."
    fi
    echo "Added $SETUP_REALM_PASS User account"
fi
if [ $SETUP_AUTH == "true" ]; then
	sudo useradd -m -p $SETUP_AUTH_PASS -s /bin/bash $SETUP_AUTH_USER
    if ! sudo grep -q "$SETUP_AUTH_USER ALL=(ALL) NOPASSWD: ALL" "/etc/sudoers.d/$SETUP_AUTH_USER"; then
        echo "$SETUP_AUTH_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$SETUP_AUTH_USER
        echo "Added $SETUP_AUTH_USER to sudoers with NOPASSWD."
    fi
    echo "Added $SETUP_AUTH_USER User account"
fi
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Install Fail2Ban"
echo "##########################################################"
echo ""
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


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "7" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Root install script finished"
echo "##########################################################"
echo ""
echo -e "\e[32m↓↓↓ For authserver - Run the following ↓↓↓\e[0m"
echo ""
echo "su - $SETUP_AUTH_USER -c 'cd /WOTLKTrinityInstaller/scripts/Setup/ && ./Auth-Install.sh all'"
echo ""
echo -e "\e[32m↓↓↓ For Dev Realm - Run the following ↓↓↓\e[0m"
echo ""
echo "su - $SETUP_REALM_USER -c 'cd /WOTLKTrinityInstaller/scripts/Setup/ && ./Realm-Dev-Install.sh all'"
echo ""
fi
fi
