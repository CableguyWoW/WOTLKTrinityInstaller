#!/bin/bash

### TRINITYCORE AUTH INSTALL SCRIPT
### TESTED WITH UBUNTU ONLY

. /WOTLKTrinityInstaller/configs/root-config
. /WOTLKTrinityInstaller/configs/repo-config
. /WOTLKTrinityInstaller/configs/auth-config

if [ $USER != "$SETUP_AUTH_USER" ]; then

echo "You must run this script under the $SETUP_AUTH_USER user!"

else

## LETS START
echo ""
echo "##########################################################"
echo "## AUTH SERVER INSTALL SCRIPT STARTING...."
echo "##########################################################"
echo ""
NUM=0
export DEBIAN_FRONTEND=noninteractive


if [ "$1" = "" ]; then
## Option List
echo "## No option selected, see list below"
echo ""
echo "- [all] : Run Full Script"
echo "- [update] : Update Source and DB"
echo ""
((NUM++)); echo "- [$NUM] : Close Authserver"
((NUM++)); echo "- [$NUM] : Pull and Setup Source"
((NUM++)); echo "- [$NUM] : Setup Authserver Config"
((NUM++)); echo "- [$NUM] : Setup Restarter"
((NUM++)); echo "- [$NUM] : Setup Backup Folder"
((NUM++)); echo "- [$NUM] : Setup Crontab"
((NUM++)); echo "- [$NUM] : Setup Alias"
((NUM++)); echo "- [$NUM] : Start Authserver"
echo ""

else

NUM=0
((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Closing Authserver"
echo "##########################################################"
echo ""
screen -XS $SETUP_AUTH_USER kill
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Pulling source"
echo "##########################################################"
echo ""
cd /home/$SETUP_AUTH_USER/
mkdir /home/$SETUP_AUTH_USER/
mkdir /home/$SETUP_AUTH_USER/server/
mkdir /home/$SETUP_AUTH_USER/logs/
mkdir /home/$SETUP_AUTH_USER/logs/crashes/
## Source install
git clone --single-branch --branch $AUTH_BRANCH "$CORE_REPO_URL" TrinityCore
## Build source
echo "Building source...."
cd /home/$SETUP_AUTH_USER/TrinityCore/
mkdir /home/$SETUP_AUTH_USER/TrinityCore/build
cd /home/$SETUP_AUTH_USER/TrinityCore/build
cmake /home/$SETUP_AUTH_USER/TrinityCore/ -DCMAKE_INSTALL_PREFIX=/home/$SETUP_AUTH_USER/server -DSCRIPTS="none" -DUSE_COREPCH=1 -DUSE_SCRIPTPCH=1 -DSERVERS=1 -DTOOLS=0 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_COREDEBUG=0 -DWITH_WARNINGS=0 && make -j $(( $(nproc) - 1 )) && make install
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Config"
echo "##########################################################"
echo ""
cd /home/$SETUP_AUTH_USER/server/etc/
if [ -f "authserver.conf.dist" ]; then
    mv "authserver.conf.dist" "authserver.conf"
    echo "Moved authserver.conf.dist to authserver.conf."
fi
## Changing Config values
echo "Changing Config values"
sed -i 's^LogsDir = ""^LogsDir = ""/home/'${SETUP_AUTH_USER}'/public/logs"^g' authserver.conf
sed -i "s/Updates.EnableDatabases = 0/Updates.EnableDatabases = 1/g" authserver.conf
sed -i "s/127.0.0.1;3306;trinity;trinity;auth/${AUTH_DB_HOST};${AUTH_DB_PORT};${AUTH_DB_USER};${AUTH_DB_PASS};${AUTH_WORLD_DB_DB}/g" authserver.conf
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "5" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Restarter"
echo "##########################################################"
echo ""
mkdir /home/$SETUP_AUTH_USER/server/scripts/
mkdir /home/$SETUP_AUTH_USER/server/scripts/Restarter/
mkdir /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/
cp -r -u /WOTLKTrinityInstaller/scripts/Restarter/Auth/ /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/
## FIX SCRIPTS PERMISSIONS
chmod +x  /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/start.sh
sed -i "s/realmname/$SETUP_AUTH_USER/g" /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/start.sh
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Crontab"
echo "##########################################################"
echo ""
crontab -r
crontab -l | { cat; echo "############## START AUTHSERVER ##############"; } | crontab -
crontab -l | { cat; echo "@reboot /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/start.sh"; } | crontab -
echo "Auth Crontab setup"
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Script Alias"
echo "##########################################################"
echo ""
if grep -Fxq "#### CUSTOM ALIAS" ~/.bashrc
then
	echo "header present"
else
	echo "" >> ~/.bashrc
	echo "#### CUSTOM ALIAS" >> ~/.bashrc
	echo "" >> ~/.bashrc
	. ~/.bashrc
	echo "header added"
fi

if grep -Fxq "## COMMANDS" ~/.bashrc
then
	echo "alias commands present"
else
	echo "## COMMANDS" >> ~/.bashrc
	echo "alias commands='cd /home/install/scripts/Setup/ && ./Auth-Install.sh && cd -'" >> ~/.bashrc
	. ~/.bashrc
fi

if grep -Fxq "## UPDATE" ~/.bashrc
then
	echo "alias update present"
else
	echo "## UPDATE" >> ~/.bashrc
	echo "alias update='cd /home/install/scripts/Setup/ && ./Auth-Install.sh update && cd -'" >> ~/.bashrc
	. ~/.bashrc
fi

echo "Added script alias to bashrc"
. ~/.bashrc
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Starting Authserver"
echo "##########################################################"
echo ""
/home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/start.sh
fi

echo ""
echo "##########################################################"
echo "## AUTH INSTALLED AND FINISHED!"
echo "##########################################################"
echo ""

fi
fi
