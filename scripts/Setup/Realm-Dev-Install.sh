#!/bin/bash

### TRINITYCORE INSTALL SCRIPT
### TESTED WITH UBUNTU ONLY

. /WOTLKTrinityInstaller/configs/root-config
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
((NUM++)); echo "- [$NUM] : Setup MySQL Database & Users"
((NUM++)); echo "- [$NUM] : Pull and Setup Source"
((NUM++)); echo "- [$NUM] : Setup Worldserver Config"
((NUM++)); echo "- [$NUM] : Pull and Setup Database"
((NUM++)); echo "- [$NUM] : Download 3.3.5a Client"
((NUM++)); echo "- [$NUM] : Setup Client Tools"
((NUM++)); echo "- [$NUM] : Run Map/DBC Extractor"
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
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup MySQL Database & Users"
echo "##########################################################"
echo ""

# World Database Setup
if ! mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "SHOW DATABASES LIKE '${REALM_DB_USER}_world';" | grep -q "${REALM_DB_USER}_world"; then
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE DATABASE ${REALM_DB_USER}_world DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
    echo "Database ${REALM_DB_USER}_world created."
else
    echo "Database ${REALM_DB_USER}_world already exists."
fi

if ! mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "SHOW DATABASES LIKE '${REALM_DB_USER}_character';" | grep -q "${REALM_DB_USER}_character"; then
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE DATABASE ${REALM_DB_USER}_character DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
    echo "Database ${REALM_DB_USER}_character created."
else
    echo "Database ${REALM_DB_USER}_character already exists."
fi

# Create the realm user if it does not already exist
if ! mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "SELECT User FROM mysql.user WHERE User = '${REALM_DB_USER}' AND Host = 'localhost';"; then
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE USER '${REALM_DB_USER}'@'localhost' IDENTIFIED BY '$REALM_DB_PASS';"
    echo "Realm DB user '${REALM_DB_USER}' created."
fi

mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT ALL PRIVILEGES ON ${REALM_DB_USER}_world.* TO '${REALM_DB_USER}'@'localhost';"
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT ALL PRIVILEGES ON ${REALM_DB_USER}_character.* TO '${REALM_DB_USER}'@'localhost';"
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "FLUSH PRIVILEGES;"
echo "Setup World DB Account"

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
git clone --single-branch --branch $CORE_BRANCH "$CORE_REPO_URL" TrinityCore
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
sed -i 's/WorldServerPort = 8085/WorldServerPort = '${SETUP_REALM_PORT}'/g' worldserver.conf
sed -i 's/RealmZone = 1/RealmZone = '${REALM_ZONE}'/g' worldserver.conf
sed -i 's/mmap.enablePathFinding = 0/mmap.enablePathFinding = 1/g' worldserver.conf
## Folders
sed -i 's^LogsDir = ""^LogsDir = "/home/'${SETUP_REALM_USER}'/server/logs"^g' worldserver.conf
sed -i 's^DataDir = "."^DataDir = "/home/'${SETUP_REALM_USER}'/server/data"^g' worldserver.conf
sed -i 's^BuildDirectory  = ""^BuildDirectory  = "/home/'${SETUP_REALM_USER}'/TrinityCore/build"^g' worldserver.conf
sed -i 's^SourceDirectory  = ""^SourceDirectory  = "/home/'${SETUP_REALM_USER}'/TrinityCore/"^g' worldserver.conf
## LoginDatabaseInfo
sed -i "s/127.0.0.1;3306;trinity;trinity;auth/${AUTH_DB_HOST};3306;${AUTH_DB_USER};${AUTH_DB_PASS};${AUTH_DB_USER};/g" worldserver.conf
## WorldDatabaseInfo
sed -i "s/127.0.0.1;3306;trinity;trinity;world/${REALM_DB_HOST};3306;${REALM_DB_USER};${REALM_DB_PASS};${REALM_DB_USER}_world/g" worldserver.conf
## CharacterDatabaseInfo
sed -i "s/127.0.0.1;3306;trinity;trinity;characters/${REALM_DB_HOST};3306;${REALM_DB_USER};${REALM_DB_PASS};${REALM_DB_USER}_character/g" worldserver.conf
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM. Downloading TDB"
echo "##########################################################"
echo ""

FILENAME="${DB_REPO_URL##*/}"           # Get the filename from the URL
SQLNAME="${FILENAME%.7z}.sql"           # Replace .7z with .sql
TARGET_DIR="/home/$SETUP_REALM_USER/server"

cd "$TARGET_DIR" || { echo "Directory does not exist: $TARGET_DIR"; exit 1; }

if [ -f "$SQLNAME" ]; then
	while true; do
		read -p "$SQLNAME already exists. Redownload? (y/n): " file_choice
		if [[ "$file_choice" =~ ^[Yy]$ ]]; then
			rm -f "$FILENAME" "$SQLNAME"  # Remove both files
			wget "$DB_REPO_URL"
			break
		elif [[ "$file_choice" =~ ^[Nn]$ ]]; then
			echo "Skipping download." && break
		else
			echo "Please answer y (yes) or n (no)."
		fi
	done
else
	wget "$DB_REPO_URL"
fi

# Ensure the file exists before extracting
if [ -f "$FILENAME" ]; then
	7z e "$FILENAME"
	rm "$FILENAME"
fi
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Download 3.3.5a Client"
echo "##########################################################"
echo ""
URL="https://btground.tk/chmi/ChromieCraft_3.3.5a.zip"
FILENAME="${URL##*/}"
cd /home/
if [ -f "$FILENAME" ]; then
    while true; do
        read -p "$FILENAME already exists. Redownload? (y/n): " file_choice
        if [[ "$file_choice" =~ ^[Yy]$ ]]; then
            rm "$FILENAME" && sudo wget $URL && break
        elif [[ "$file_choice" =~ ^[Nn]$ ]]; then
            echo "Skipping download." && break
        else
            echo "Please answer y (yes) or n (no)."
        fi
    done
else
	sudo wget $URL
fi
if [ -d "/home/WoW335" ]; then
    while true; do
        read -p "WoW335 Folder already exists. Reextract? (y/n): " folder_choice
        if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
            sudo unzip "$FILENAME" && break
        elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
            echo "Skipping extraction." && break
        else
            echo "Please answer y (yes) or n (no)."
        fi
    done
else
	sudo unzip "$FILENAME"
fi
if [ -d "/home/ChromieCraft_3.3.5a" ]; then
	sudo mv -f /home/ChromieCraft_3.3.5a /home/WoW335
fi
if [ -d "/home/WoW335" ]; then
	sudo chmod -R 777 /home/WoW335
fi
if [ -f "/home/$FILENAME" ]; then
    while true; do
        read -p "Would you like to delete the 3.3.5a client zip folder to save folder space? (y/n): " folder_choice
        if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
            sudo rm $FILENAME && break
        elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
            echo "Skipping deletion." && break
        else
            echo "Please answer y (yes) or n (no)."
        fi
    done
fi
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Client Tools"
echo "##########################################################"
echo ""
cp /home/$SETUP_REALM_USER/server/bin/mapextractor /home/WoW335/
cp /home/$SETUP_REALM_USER/server/bin/vmap4extractor /home/WoW335/
cp /home/$SETUP_REALM_USER/server/bin/mmaps_generator /home/WoW335/
cp /home/$SETUP_REALM_USER/server/bin/vmap4assembler /home/WoW335/
echo "Client tools copied over to /home/WoW335"
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Run Map/DBC Extractor"
echo "##########################################################"
echo ""
cd /home/WoW335/
if [ -d "/home/WoW335/maps" ]; then
    while true; do
        read -p "maps Folder already exists. Reextract? (y/n): " folder_choice
        if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
            ./mapextractor && break
        elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
            echo "Skipping extraction." && break
        else
            echo "Please answer y (yes) or n (no)."
        fi
    done
else
	./mapextractor
fi
while true; do
	read -p "Would you like to copy the maps/dbc data folders? (y/n): " folder_choice
	if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
		echo "Copying dbc folder"
		cp -r /home/WoW335/dbc /home/$SETUP_REALM_USER/server/data/
		echo "Copying Cameras folder"
		cp -r /home/WoW335/Cameras /home/$SETUP_REALM_USER/server/data/
		echo "Copying maps folder"
		cp -r /home/WoW335/maps /home/$SETUP_REALM_USER/server/data/
		break
	elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
		echo "Skipping data copy." && break
	else
		echo "Please answer y (yes) or n (no)."
	fi
done

fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Run VMap Extractor"
echo "##########################################################"
echo ""
cd /home/WoW335/
if [ -d "/home/WoW335/vmaps" ]; then
    while true; do
        read -p "vmaps Folder already exists. Reextract? (y/n): " folder_choice
        if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
            ./vmap4extractor && ./vmap4assembler && break
        elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
            echo "Skipping extraction." && break
        else
            echo "Please answer y (yes) or n (no)."
        fi
    done
else
	./vmap4extractor && ./vmap4assembler
fi
while true; do
	read -p "Would you like to copy the vmap data folders? (y/n): " folder_choice
	if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
		echo "Copying Buildings folder"
		cp -r /home/WoW335/Buildings /home/$SETUP_REALM_USER/server/data/
		echo "Copying vmaps folder"
		cp -r /home/WoW335/vmaps /home/$SETUP_REALM_USER/server/data/
		break
	elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
		echo "Skipping data copy." && break
	else
		echo "Please answer y (yes) or n (no)."
	fi
done
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Run Mmaps Extractor"
echo "##########################################################"
echo ""
cd /home/WoW335/
if [ -d "/home/WoW335/mmaps" ]; then
    while true; do
        read -p "mmaps Folder already exists. Reextract? (y/n): " folder_choice
        if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
            ./mmaps_generator && break
        elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
            echo "Skipping extraction." && break
        else
            echo "Please answer y (yes) or n (no)."
        fi
    done
else
	./mmaps_generator
fi
while true; do
	read -p "Would you like to copy the mmaps data folders? (y/n): " folder_choice
	if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
		echo "Copying mmaps folder"
		cp -r /home/WoW335/mmaps /home/$SETUP_REALM_USER/server/data/
		break
	elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
		echo "Skipping data copy." && break
	else
		echo "Please answer y (yes) or n (no)."
	fi
done
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
mysql --host=$REALM_DB_HOST -h $AUTH_DB_HOST -u $AUTH_DB_USER -p$AUTH_DB_PASS << EOF
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
sudo cp -r -u /WOTLKTrinityInstaller/scripts/Restarter/World/* /home/$SETUP_REALM_USER/server/scripts/Restarter/World/
## FIX SCRIPTS PERMISSIONS
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/start_gdb.sh
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/restarter_world_gdb.sh
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/gdbcommands
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/start.sh
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/restarter_world.sh
sudo sed -i "s/realmname/$SETUP_REALM_USER/g" /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/start_gdb.sh
sudo sed -i "s/realmname/$SETUP_REALM_USER/g" /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/start.sh
fi


if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
((NUM++))
echo ""
echo "##########################################################"
echo "## $NUM.Setup Misc Scripts"
echo "##########################################################"
echo ""
cp -r -u /WOTLKTrinityInstaller/scripts/Setup/Clean-Logs.sh /home/$SETUP_REALM_USER/server/scripts/
chmod +x  /home/$SETUP_REALM_USER/server/scripts/Clean-Logs.sh
cd /home/$SETUP_REALM_USER/server/scripts/
sudo sed -i "s^USER^${SETUP_REALM_USER}^g" Clean-Logs.sh
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
echo -e "\e[32m↓↓↓ To access the worldserver - Run the following ↓↓↓\e[0m"
echo ""
echo "su - $SETUP_REALM_USER -c 'screen -r $SETUP_REALM_USER'"
echo ""
echo -e "\e[32m↓↓↓ To access the authserver - Run the following ↓↓↓\e[0m"
echo ""
echo "su - $SETUP_AUTH_USER -c 'screen -r $SETUP_AUTH_USER'"
echo ""


fi
fi
