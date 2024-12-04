#!/bin/bash

### SCRIPT INSTALL SCRIPT
### TESTED WITH DEBIAN ONLY

. /root/WOTLKTrinityInstaller/configs/root-config
. /root/WOTLKTrinityInstaller/configs/repo-config

if [ ! -f ./configs/root-config ] || [ ! -f ./configs/repo-config ]; then
    echo "Config file not found! Add configs!"
    exit;
fi

if [ -z "$INSTALL_PATH" ]; then
    echo "Install path config option missing?!"
    exit;
fi

if [ "$1" = "" ]; then
echo ""
echo "## No option selected, see list below"
echo ""
echo "- [all] : Run Full Script"
echo ""
((NUM++)); echo "- [$NUM] : Install Prerequisites" 
((NUM++)); echo "- [$NUM] : Update Script permissions"
((NUM++)); echo "- [$NUM] : Update Script permissions"
((NUM++)); echo "- [$NUM] : Install Mysql Apt"
((NUM++)); echo "- [$NUM] : Randomize Passwords"
echo ""

else

### LETS START
echo ""
echo "##########################################################"
echo "## INIT SCRIPT STARTING...."
echo "##########################################################"
echo ""
export DEBIAN_FRONTEND=noninteractive


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Install Prerequisites"
echo "##########################################################"
echo ""
sudo apt install p7zip-full dos2unix gnupg --assume-yes
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Update Config permissions"
echo "##########################################################"
echo ""
find /root/WOTLKTrinityInstaller/ -type d -exec chmod 755 {} +
find /root/WOTLKTrinityInstaller/ -type f -exec chmod 755 {} +
sudo chmod -R 775 /root/WOTLKTrinityInstaller/
find /root/WOTLKTrinityInstaller/ -type f -exec dos2unix {} \;
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Update Script permissions"
echo "##########################################################"
echo ""
find /root/WOTLKTrinityInstaller/scripts -type d -exec chmod 755 {} +
find /root/WOTLKTrinityInstaller/scripts -type f -exec chmod 755 {} +
sudo chmod -R 775 /root/WOTLKTrinityInstaller/
find /root/WOTLKTrinityInstaller/*.sh -type f -exec dos2unix {} \;
find /root/WOTLKTrinityInstaller/configs/ -type f -exec dos2unix {} \;
cd /root/WOTLKTrinityInstaller/scripts/Setup/
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Install Mysql Apt"
echo "##########################################################"
echo ""
wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb -O /tmp/mysql-apt-config_all.deb
DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/mysql-apt-config_all.deb
sudo apt update -y
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Randomize Passwords"
echo "##########################################################"
echo ""
replace_randomizepass() 
{
    local files="$1"         # File pattern to search for (e.g., *.txt)
    local min_length="${2:-12}"     # Minimum length of the password; default is 12
    local max_length="${3:-16}"     # Maximum length of the password; default is 16

    # Loop through the files matching the pattern
    for file in $files; do
        if [[ -f "$file" ]]; then   # Check if it's a file
            while IFS= read -r line; do
                # Replace "RANDOMIZEPASS" with a new random password
                echo "${line//RANDOMIZEPASS/$(generate_random_password $min_length $max_length)}"
            done < "$file" > "$file.tmp"  # Write the output to a temp file
            mv "$file.tmp" "$file"        # Overwrite the original file
            echo "Processed: $file"
        fi
    done
}

generate_random_password() 
{
    local length=$((RANDOM % (max_length - min_length + 1) + min_length))
    # Use /dev/urandom for generating a random password
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
}

if [ "$RANDOMIZE_PASSWORDS" = "true" ]; then
    replace_randomizepass "/root/WOTLKTrinityInstaller/configs/*"  # Example: replace in all .txt files
else
    echo ""
    echo ""
    echo "Password randomiztion disabled, the default password is password123"
    echo ""
    echo ""
    if [ "$REMOTE_DB_SETUP" = "true" ]; then
        echo "Its highly recommended to change the remote MYSQL user password as it will be public."
        echo "YOU HAVE BEEN WARNED!"
        echo ""
        read -p "Do you want to change the password? (y/n): " yn
        if [[ "$yn" =~ ^[Yy]$ ]]; then
            read -sp "Enter the new password: " NEW_PASSWORD
            echo ""  # New line after password input
            [[ -f "/root/WOTLKTrinityInstaller/configs/root-config" ]] && sed -i "s/REMOTE_DB_PASS=\".*\"/REMOTE_DB_PASS=\"$NEW_PASSWORD\"/" "$CONFIG_FILE" && echo "Password updated successfully in $CONFIG_FILE." || echo "Error: Configuration file does not exist."
        fi
    fi
fi
fi

echo "##########################################################"
echo "INIT FINISHED"
echo ""
echo "All passwords are stored in - /root/WOTLKTrinityInstaller/configs/"
echo ""
echo "Next - Run the following : cd /root/WOTLKTrinityInstaller/scripts/Setup/ && ./Root-Install.sh all"
echo "##########################################################"

fi