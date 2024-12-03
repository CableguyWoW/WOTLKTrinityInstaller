#!/bin/bash

### SCRIPT INSTALL SCRIPT
### TESTED WITH DEBIAN ONLY

. /root/WOTLKTrinityInstaller/configs/root-config
. /root/WOTLKTrinityInstaller/configs/repo-config

if [ ! -f ./configs/root-config ] || [ ! -f ./configs/repo-config ]; then
    echo "Config file not found! Add configs!"
else
if [ -z "$INSTALL_PATH" ]; then
    echo "Install path config option missing?!"
else

### LETS START
echo "##########################################################"
echo "## INIT SCRIPT STARTING...."
echo "##########################################################"
export DEBIAN_FRONTEND=noninteractive

sudo apt install p7zip-full dos2unix gnupg --assume-yes

## Updating config permissions
echo "Updating config permissions"
find /root/WOTLKTrinityInstaller/ -type d -exec chmod 755 {} +
find /root/WOTLKTrinityInstaller/ -type f -exec chmod 755 {} +
sudo chmod -R 775 /root/WOTLKTrinityInstaller/
find /root/WOTLKTrinityInstaller/ -type f -exec dos2unix {} \;

## Updating script permissions
echo "Updating Script permissions"
find /root/WOTLKTrinityInstaller/scripts -type d -exec chmod 755 {} +
find /root/WOTLKTrinityInstaller/scripts -type f -exec chmod 755 {} +
sudo chmod -R 775 /root/WOTLKTrinityInstaller/
find /root/WOTLKTrinityInstaller/*.sh -type f -exec dos2unix {} \;
find /root/WOTLKTrinityInstaller/configs/ -type f -exec dos2unix {} \;
cd /root/WOTLKTrinityInstaller/scripts/Setup/

wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb -O /tmp/mysql-apt-config_all.deb
DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/mysql-apt-config_all.deb
sudo apt update -y

echo "##########################################################"
echo "INIT FINISHED"
echo "Run the following : cd /root/WOTLKTrinityInstaller/scripts/Setup/ && ./Root-Install.sh all"
echo "##########################################################"

fi
fi
