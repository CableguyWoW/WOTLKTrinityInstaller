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
if [ "$SETUP_TSWOW" = "true" ] then
    # Nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
    source ~/.bashrc
    nvm install 20.18.0
    nvm use 20.18.0
    # Cmake
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
    sudo apt-add-repository 'deb https://apt.kitware.com/debian/ bookworm main'
    sudo apt update
    sudo apt install cmake
fi
#TrinityCore Dependencies
sudo apt-get install git unzip screen clang cmake make gdb gcc g++ libmysqlclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev libboost-all-dev p7zip --assume-yes
update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100
update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang 100
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM. Install MySQL Server"
echo "##########################################################"
echo ""

# Set root password for MySQL installation
echo "mysql-server mysql-server/root_password password $ROOT_PASS" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $ROOT_PASS" | sudo debconf-set-selections

# Install MySQL server
apt-get -y install mysql-server

# Configure MySQL settings
MY_CNF="/etc/mysql/mysql.conf.d/mysqld.cnf"

# Add skip-networking if not present
if ! grep -q "^skip-networking" "$MY_CNF"; then
    echo "skip-networking" | sudo tee -a "$MY_CNF" > /dev/null
fi

# Add max_allowed_packet if not present
if ! grep -q "^max_allowed_packet" "$MY_CNF"; then
    echo "max_allowed_packet = 128M" | sudo tee -a "$MY_CNF" > /dev/null
fi

# Add sql_mode if not present
if ! grep -q "^sql_mode" "$MY_CNF"; then
    echo 'sql_mode=""' | sudo tee -a "$MY_CNF" > /dev/null
fi

# Conditionally add bind address if REMOTE_DB_SETUP is true
if [ "$REMOTE_DB_SETUP" = "true" ]; then
    if ! grep -q "^bind-address" "$MY_CNF"; then
        echo "bind-address = 0.0.0.0" | sudo tee -a "$MY_CNF" > /dev/null
    fi
fi

# Restart the MySQL service to apply changes
service mysql restart

# Update MySQL user settings
mysql -u root -p$ROOT_PASS << EOF
USE mysql;
UPDATE user SET user='$ROOT_USER' WHERE user='root';
ALTER USER '$ROOT_USER'@'localhost' IDENTIFIED WITH mysql_native_password BY '$ROOT_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$ROOT_USER'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
quit
EOF

# Remove skip-networking if not required
sudo sed -i '/^skip-networking/d' "$MY_CNF"

# Optional: Restart MySQL again after user adjustments
service mysql restart
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM. Setting up MySQL Users"
echo "##########################################################"
echo ""

# Remote DB User Setup
if [ "$REMOTE_DB_SETUP" == "true" ]; then
    echo "Checking if remote DB user '$REMOTE_DB_USER' exists at host '$REMOTE_DB_HOST'..."
    
    # Check if the remote user exists
    if ! mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "SELECT User FROM mysql.user WHERE User = '$REMOTE_DB_USER' AND Host = '$REMOTE_DB_HOST';" | grep -q "$REMOTE_DB_USER"; then
        mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE USER '$REMOTE_DB_USER'@'$REMOTE_DB_HOST' IDENTIFIED BY '$REMOTE_DB_PASS';"
        if [[ $? -eq 0 ]]; then
            echo "Remote DB user '$REMOTE_DB_USER' created."
        else
            echo "Failed to create remote DB user '$REMOTE_DB_USER'."
            exit 1
        fi
    else
        echo "Remote DB user '$REMOTE_DB_USER' already exists."
    fi

    # Grant necessary permissions
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT ALL PRIVILEGES ON *.* TO '$REMOTE_DB_USER'@'$REMOTE_DB_HOST' WITH GRANT OPTION;"
    if [[ $? -eq 0 ]]; then
        echo "Granted all privileges to '$REMOTE_DB_USER'@'$REMOTE_DB_HOST'."
    else
        echo "Failed to grant privileges to '$REMOTE_DB_USER'@'$REMOTE_DB_HOST'."
        exit 1
    fi
    
    # Flush privileges
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "FLUSH PRIVILEGES;"
    echo "Flushed privileges."
fi
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
