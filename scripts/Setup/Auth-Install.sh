#!/bin/bash

### TRINITYCORE AUTH INSTALL SCRIPT
### TESTED WITH UBUNTU ONLY

. /root/WOTLKTrinityInstaller/configs/root-config
. /root/WOTLKTrinityInstaller/configs/backup-config
. /root/WOTLKTrinityInstaller/configs/repo-config
. /root/WOTLKTrinityInstaller/configs/auth-config

if [ $USER != "$SETUP_AUTH_USER" ]; then

echo "You must run this script under the $SETUP_AUTH_USER user!"

else

## LETS START
echo "##########################################################"
echo "## AUTH SERVER INSTALL SCRIPT STARTING...."
echo "##########################################################"
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
((NUM++)); echo "- [$NUM] : Setup MySQL Users and DB"
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
echo "##########################################################"
echo "## $NUM.Closing Authserver"
echo "##########################################################"
echo "Closing authserver for setup."
screen -XS $SETUP_AUTH_USER kill
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo "##########################################################"
echo "## $NUM.Pulling source"
echo "##########################################################"
cd /home/$SETUP_AUTH_USER/
mkdir /home/$SETUP_AUTH_USER/
mkdir /home/$SETUP_AUTH_USER/server/
mkdir /home/$SETUP_AUTH_USER/logs/
mkdir /home/$SETUP_AUTH_USER/logs/crashes/
## Source install
git clone --single-branch --branch $AUTH_BRANCH "$CORE_REPO_URL" .
## Build source
echo "Building source...."
cd /home/$SETUP_AUTH_USER/TrinityCore/
mkdir build && cd build
cmake ../ -DCMAKE_INSTALL_PREFIX=/home/$SETUP_AUTH_USER/server -DSCRIPTS="none" -DUSE_COREPCH=1 -DUSE_SCRIPTPCH=1 -DSERVERS=1 -DTOOLS=0 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_COREDEBUG=0 -DWITH_WARNINGS=0 && make -j $(( $(nproc) - 1 )) && make install
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo "##########################################################"
echo "## $NUM.Setup Config"
echo "##########################################################"
cd /home/$SETUP_AUTH_USER/server/etc/
mv authserver.conf.dist authserver.conf
## Changing Config values
echo "Changing Config values"
sed -i 's^LogsDir = ""^LogsDir = ""/home/'${SETUP_AUTH_USER}'/public/logs"^g' authserver.conf
sed -i "s/Updates.EnableDatabases = 0/Updates.EnableDatabases = 1/g" authserver.conf
sed -i "s/127.0.0.1;3306;trinity;trinity;auth/${AUTH_DB_HOST};${AUTH_DB_PORT};${AUTH_DB_USER};${AUTH_DB_PASS};${AUTH_WORLD_DB_DB}/g" worldserver.conf
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo "##########################################################"
echo "## $NUM.Setup MySQL"
echo "##########################################################"
mysql --port=$AUTH_DB_PORT -u $AUTH_DB_USER -p$AUTH_DB_PASS -e "CREATE DATABASE auth DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql --port=$AUTH_DB_PORT -u $AUTH_DB_USER -p$AUTH_DB_PASS -e "CREATE DATABASE auth_custom DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql --port=$AUTH_DB_PORT -u $AUTH_DB_USER -p$AUTH_DB_PASS -e "GRANT USAGE ON auth.* TO '$AUTH_DB_USER'@'localhost' IDENTIFIED BY '$AUTH_DB_PASS' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;"
mysql --port=$AUTH_DB_PORT -u $AUTH_DB_USER -p$AUTH_DB_PASS -e "GRANT USAGE ON auth_custom.* TO '$AUTH_DB_USER'@'localhost' IDENTIFIED BY '$AUTH_DB_PASS' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;"
mysql --port=$AUTH_DB_PORT -u $AUTH_DB_USER -p$AUTH_DB_PASS -e "GRANT ALL PRIVILEGES ON auth.* TO '$AUTH_DB_USER'@'localhost' WITH GRANT OPTION;"
mysql --port=$AUTH_DB_PORT -u $AUTH_DB_USER -p$AUTH_DB_PASS -e "GRANT ALL PRIVILEGES ON auth_custom.* TO '$AUTH_DB_USER'@'localhost' WITH GRANT OPTION;"
mysql --port=$AUTH_DB_PORT -u $AUTH_DB_USER -p$AUTH_DB_PASS -e "FLUSH PRIVILEGES;"
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "5" ]; then
echo "##########################################################"
echo "## $NUM.Setup Restarter"
echo "##########################################################"
mkdir /home/$SETUP_AUTH_USER/server/scripts/
mkdir /home/$SETUP_AUTH_USER/server/scripts/Restarter/
mkdir /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/
cp -r -u /home/$INSTALL_PATH/scripts/Restarter/Auth/. /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/
## FIX SCRIPTS PERMISSIONS
chmod +x  /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/start.sh
sed -i "s/realmname/$SETUP_AUTH_USER/g" /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/start.sh
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo "##########################################################"
echo "## $NUM.Setup Crontab"
echo "##########################################################"
crontab -l | { cat; echo "############## START AUTHSERVER ##############"; } | crontab -
crontab -l | { cat; echo "@reboot /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/start.sh"; } | crontab -
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo "##########################################################"
echo "## $NUM.Setup Script Alias"
echo "##########################################################"
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
echo "##########################################################"
echo "## $NUM.Starting Authserver"
echo "##########################################################"
/home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/start.sh
fi

echo "##########################################################"
echo "## AUTH INSTALLED AND FINISHED!"
echo "##########################################################"

fi
