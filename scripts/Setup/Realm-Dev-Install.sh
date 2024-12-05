#!/bin/bash

### TRINITYCORE INSTALL SCRIPT
### TESTED WITH UBUNTU ONLY

. /WOTLKTrinityInstaller/configs/root-config
. /WOTLKTrinityInstaller/configs/backup-config
. /WOTLKTrinityInstaller/configs/repo-config
. /WOTLKTrinityInstaller/configs/auth-config
. /WOTLKTrinityInstaller/configs/realm-dev-config

if [ $USER != "$SETUP_REALM_USER" ]; then

echo "You must run this script under the $SETUP_REALM_USER user!"

else

## LETS START
echo ""
echo "##########################################################"
echo "## DEV REALM INSTALL SCRIPT STARTING...."
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
echo "- [startrealm debug] : Start Realm screen under GDB"
echo "- [startrealm release] : Start Realm screen under release"
echo "- [stoprealm] : Stops all screen sessions on the user"
echo ""
((NUM++)); echo "- [$NUM] : Close Worldserver" 
((NUM++)); echo "- [$NUM] : Pull and Setup Source"
((NUM++)); echo "- [$NUM] : Setup Worldserver Config"
((NUM++)); echo "- [$NUM] : Pull and Setup Database"
((NUM++)); echo "- [$NUM] : Download 3.3.5a Client"
((NUM++)); echo "- [$NUM] : Setup Client Tools"
((NUM++)); echo "- [$NUM] : Run Map Extractor"
((NUM++)); echo "- [$NUM] : Run VMap Extractor"
((NUM++)); echo "- [$NUM] : Run Mmaps Extractor"
((NUM++)); echo "- [$NUM] : Setup Realmlist"
((NUM++)); echo "- [$NUM] : Setup World Restarter Scripts"
((NUM++)); echo "- [$NUM] : Setup Misc Scripts"
((NUM++)); echo "- [$NUM] : Setup Crontab"
((NUM++)); echo "- [$NUM] : Setup Script Alias"
((NUM++)); echo "- [$NUM] : Start Worldserver"
echo ""

else


NUM=0
((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Closing Worldserver"
echo "##########################################################"
echo ""
screen -XS $SETUP_REALM_USER kill
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Pulling Source"
echo "##########################################################"
echo ""
cd /home/$SETUP_REALM_USER/
mkdir /home/$SETUP_REALM_USER/server/
mkdir /home/$SETUP_REALM_USER/server/logs/
mkdir /home/$SETUP_REALM_USER/server/logs/crashes/
mkdir /home/$SETUP_REALM_USER/server/data/
## Source install
git clone --single-branch --branch $CORE_BRANCH "https://$CORE_REPO_URL" TrinityCore
## Build source
echo "Building Source"
cd /home/$SETUP_REALM_USER/TrinityCore/
mkdir /home/$SETUP_REALM_USER/TrinityCore/build
cd /home/$SETUP_REALM_USER/TrinityCore/build
cmake /home/$SETUP_REALM_USER/TrinityCore/ -DCMAKE_INSTALL_PREFIX=/home/$SETUP_REALM_USER/server -DSCRIPTS_EASTERNKINGDOMS="disabled" -DSCRIPTS_EVENTS="disabled" -DSCRIPTS_KALIMDOR="disabled" -DSCRIPTS_NORTHREND="disabled" -DSCRIPTS_OUTDOORPVP="disabled" -DSCRIPTS_OUTLAND="disabled" -DWITH_DYNAMIC_LINKING=ON -DSCRIPTS="dynamic" -DSCRIPTS_CUSTOM="dynamic" -DUSE_COREPCH=1 -DUSE_SCRIPTPCH=1 -DSERVERS=1 -DTOOLS=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_COREDEBUG=0 -DWITH_WARNINGS=0 && make -j $(( $(nproc) - 1 )) && make install
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Config"
echo "##########################################################"
echo ""
cd /home/$SETUP_REALM_USER/server/etc/
mv worldserver.conf.dist worldserver.conf
## Changing Config values
echo "Changing Config values"
## Misc Edits
sed -i 's/RealmID = 1/RealmID = '${REALM_ID}'/g' worldserver.conf
sed -i 's/WorldServerPort = 8085/WorldServerPort = '${SETUP_DEV_REALM_PORT}'/g' worldserver.conf
sed -i 's/RealmZone = 1/RealmZone = '${REALM_ZONE}'/g' worldserver.conf
sed -i 's/mmap.enablePathFinding = 0/mmap.enablePathFinding = 1/g' worldserver.conf
## Folders
sed -i 's^LogsDir = ""^LogsDir = "/home/'${SETUP_REALM_USER}'/public/data"^g' worldserver.conf
sed -i 's^DataDir = "."^DataDir = "/home/'${SETUP_REALM_USER}'/public/logs"^g' worldserver.conf
DataDir = "."
sed -i 's^BuildDirectory  = ""^BuildDirectory  = "/home/'${SETUP_REALM_USER}'/TrinityCore/build"^g' worldserver.conf
sed -i 's^SourceDirectory  = ""^SourceDirectory  = "/home/'${SETUP_REALM_USER}'/TrinityCore/"^g' worldserver.conf
## LoginDatabaseInfo
sed -i "s/127.0.0.1;3306;trinity;trinity;auth/${REALM_DB_HOST};${REALM_DB_PORT};${REALM_DB_USER};${REALM_DB_PASS};${AUTH_WORLD_DB_DB}/g" worldserver.conf
## WorldDatabaseInfo
sed -i "s/127.0.0.1;3306;trinity;trinity;world/${REALM_DB_HOST};${REALM_DB_PORT};${REALM_DB_USER};${REALM_DB_PASS};${REALM_DB_USER}_world/g" worldserver.conf
## CharacterDatabaseInfo
sed -i "s/127.0.0.1;3306;trinity;trinity;characters/${REALM_DB_HOST};${REALM_DB_PORT};${REALM_DB_USER};${REALM_DB_PASS};${REALM_DB_USER}_character/g" worldserver.conf
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Downloading TDB"
echo "##########################################################"
echo ""
# Define variables
FILENAME="${DB_REPO_URL##*/}" # Get the filename from the URL
SQLNAME="${FILENAME%.7z}.sql" # Replace .7z with .sql
TARGET_DIR="/home/$SETUP_REALM_USER/server/bin" # Change this to your target directory
# Remove existing files to avoid conflicts
rm -f "$FILENAME" "$SQLNAME"
# Download, extract, move, and clean up in one line
curl -L -o "$FILENAME" "$DB_REPO_URL"
7z e "$FILENAME"
mv "$SQLNAME" "$TARGET_DIR"
rm "$FILENAME"
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Download 3.3.5a Client"
echo "##########################################################"
echo ""
cd /home/$SETUP_REALM_USER/
wget $335_CLIENT_URL
URL=$335_CLIENT_URL
FILENAME="${URL##*/}"
unzip "$FILENAME"
mv /home/$SETUP_REALM_USER/ChromieCraft_3.3.5a /home/$SETUP_REALM_USER/WoW335
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Client Tools"
echo "##########################################################"
echo ""
cp /home/$SETUP_REALM_USER/server/bin/mapextractor /home/$SETUP_REALM_USER/WoW335/
cp /home/$SETUP_REALM_USER/server/bin/vmap4extractor /home/$SETUP_REALM_USER/WoW335/
cp /home/$SETUP_REALM_USER/server/bin/mmaps_generator /home/$SETUP_REALM_USER/WoW335/
cp /home/$SETUP_REALM_USER/server/bin/vmap4assembler /home/$SETUP_REALM_USER/WoW335/
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Run Map Extractor"
echo "##########################################################"
echo ""
cd /home/$SETUP_REALM_USER/WoW335/ && ./mapextractor
cp /home/$SETUP_REALM_USER/WoW335/dbc /home/$SETUP_REALM_USER/server/data/
cp /home/$SETUP_REALM_USER/WoW335/Cameras /home/$SETUP_REALM_USER/server/data/
cp /home/$SETUP_REALM_USER/WoW335/maps /home/$SETUP_REALM_USER/server/data/
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Run VMap Extractor"
echo "##########################################################"
echo ""
cd /home/$SETUP_REALM_USER/WoW335/ && ./vmap4extractor && ./vmap4assembler
cp /home/$SETUP_REALM_USER/WoW335/Buildings /home/$SETUP_REALM_USER/server/data/
cp /home/$SETUP_REALM_USER/WoW335/vmaps /home/$SETUP_REALM_USER/server/data/
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Run Mmaps Extractor"
echo "##########################################################"
echo ""
cd /home/$SETUP_REALM_USER/WoW335/ && ./mmaps_generator
cp /home/$SETUP_REALM_USER/WoW335/mmaps /home/$SETUP_REALM_USER/server/data/
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Update Realmlist"
echo "##########################################################"
echo ""
if [ $SETUP_REALMLIST == "true" ]; then
# Get the external IP address
EXTERNAL_IP=$(curl -s http://ifconfig.me)
mysql --host=$REALM_DB_HOST --port=$REALM_DB_PORT -h $AUTH_DB_HOST -u $AUTH_DB_USER -p$AUTH_DB_PASS << EOF
use auth
DELETE from realmlist where id = $REALM_ID;
REPLACE INTO realmlist VALUES ('$REALM_ID', '$REALM_NAME', '$EXTERNAL_IP', '$EXTERNAL_IP', '255.255.255.0', '$SETUP_DEV_REALM_PORT', '0', '0', '53', '2', '0', '12340');
quit
EOF
fi
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Linux Restarter Scripts"
echo "##########################################################"
echo ""
mkdir /home/$SETUP_REALM_USER/server/scripts/
mkdir /home/$SETUP_REALM_USER/server/scripts/Restarter/
mkdir /home/$SETUP_REALM_USER/server/scripts/Restarter/World/
sudo cp -r -u /WOTLKTrinityInstaller/scripts/Restarter/World/ /home/$SETUP_AUTH_USER/server/scripts/Restarter/World/
## FIX SCRIPTS PERMISSIONS
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/start_gdb.sh
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/restarter_world_gdb.sh
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/gdbcommands
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/start.sh
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/restarter_world.sh
sed -i "s/realmname/$SETUP_REALM_USER/g" /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/start_gdb.sh
sed -i "s/realmname/$SETUP_REALM_USER/g" /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/start.sh
fi


if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
((NUM++))
echo ""
echo "##########################################################"
echo "## $NUM.Setup Misc Scripts"
echo "##########################################################"
echo ""
cp -r -u /home/$INSTALL_PATH/scripts/Clean-Logs.sh /home/$SETUP_REALM_USER/server/scripts/
chmod +x  /home/$SETUP_REALM_USER/server/scripts/Clean-Logs.sh
cd /home/$SETUP_REALM_USER/server/scripts/
sed -i "s^USER^${SETUP_REALM_USER}^g" Clean-Logs.sh
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Crontab"
echo "##########################################################"
echo ""
crontab -r
if [ $SETUP_TYPE == "GDB" ]; then
	echo "Setup Restarter in GDB mode...."
	crontab -l | { cat; echo "############## START WORLD ##############"; } | crontab -
	crontab -l | { cat; echo "#### GDB WORLD"; } | crontab -
	crontab -l | { cat; echo "@reboot /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/start_gdb.sh"; } | crontab -
	crontab -l | { cat; echo "#### NORMAL WORLD"; } | crontab -
	crontab -l | { cat; echo "#@reboot /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/start.sh"; } | crontab -
fi
if [ $SETUP_TYPE == "Normal" ]; then
	echo "Setup Restarter in Normal mode...."
	crontab -l | { cat; echo "############## START WORLD ##############"; } | crontab -
	crontab -l | { cat; echo "#### GDB WORLD"; } | crontab -
	crontab -l | { cat; echo "#@reboot /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/start_gdb.sh"; } | crontab -
	crontab -l | { cat; echo "#### NORMAL WORLD"; } | crontab -
	crontab -l | { cat; echo "@reboot /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/start.sh"; } | crontab -
fi
## SETUP CRONTAB BACKUPS
crontab -l | { cat; echo "############## MISC SCRIPTS ##############"; } | crontab -
crontab -l | { cat; echo "* */1* * * * /home/$SETUP_REALM_USER/server/scripts/Clean-Logs.sh"; } | crontab -
echo "$SETUP_REALM_USER Realm Crontab setup"
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
	echo "alias commands='cd /home/install/scripts/Setup/ && ./Realm-Dev-Install.sh && cd -'" >> ~/.bashrc
	. ~/.bashrc
fi

if grep -Fxq "## START REALM" ~/.bashrc
then
	echo "alias startrealm present"
else
	echo "## START REALM" >> ~/.bashrc
	echo "startrealm()" >> ~/.bashrc
	echo "{" >> ~/.bashrc
	echo "if [ "$1" = "debug" ]; then " >> ~/.bashrc
	echo "cd /home/dev/server/scripts/Restarter/World/GDB/ && ./start_gdb.sh && cd - " >> ~/.bashrc
	echo "fi" >> ~/.bashrc
	echo "if [ "$1" = "release" ]; then" >> ~/.bashrc
	echo "cd /home/dev/server/scripts/Restarter/World/Normal/ && ./start.sh && cd -" >> ~/.bashrc
	echo "fi" >> ~/.bashrc
	echo "}" >> ~/.bashrc
	. ~/.bashrc
fi

if grep -Fxq "## STOP REALM" ~/.bashrc
then
	echo "alias update present"
else
	echo "## STOP REALM" >> ~/.bashrc
	echo "alias stoprealm='killall screen'" >> ~/.bashrc
	. ~/.bashrc
fi

echo "Added script alias to bashrc"
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Start Server"
echo "##########################################################"
echo ""
if [ $SETUP_TYPE == "GDB" ]; then
	echo "REALM STARTED IN GDB MODE!"
	/home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/start_gdb.sh
fi
if [ $SETUP_TYPE == "Normal" ]; then
	echo "REALM STARTED IN NORMAL MODE!"
	/home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/start.sh
fi
fi


echo ""
echo "##########################################################"
echo "## DEV REALM INSTALLED AND FINISHED!"
echo "##########################################################"
echo ""



fi
fi
