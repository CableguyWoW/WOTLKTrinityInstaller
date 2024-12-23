# WOTLKTrinityInstaller

**WOTLKTrinityInstaller** is tool that helps you set up **TrinityCore 3.3.5a** servers on **Debian 12**. With this installer, you can quickly configure your server environment so you can focus on your custom creations.

## Feature Highlights

- **Install Requirements**: Quickly installs all necessary software to run TrinityCore on Linux.
- **Source Code Management**: Downloads the TrinityCore source code and sets up both the Auth server and World server.
- **Client Data Generation**: Downloads the 3.3.5a Client and Extract DBC/Maps/VMaps/MMAPs automatically.
- **MySQL Setup**: Automatically installs and configures MySQL, including random password generation and enabling remote access.
- **Database Configuration**: Creates the required MySQL databases and user accounts.
- **Safety Measures**: Configures a firewall and installs **Fail2Ban** for enhanced security against bruteforce.

## Installation

To install **WOTLKTrinityInstaller**, run the following commands as the root user:

```bash
cd / && rm -rf WOTLKTrinityInstaller && apt-get install git sudo -y && git clone https://github.com/CableguyWoW/WOTLKTrinityInstaller/ WOTLKTrinityInstaller && cd WOTLKTrinityInstaller && chmod +x Init.sh && ./Init.sh all
```


## Script Functions

### Root Functions
The following tasks are handled by the Root user:

- **Install Prerequisites**: Install all necessary libraries and dependencies.
- **Update Script Permissions**: Ensure the script has the correct permissions to execute.
- **Install MySQL APT**: Install the MySQL APT repository to manage MySQL installations.
- **Randomize Passwords**: Generate secure, random passwords for MySQL users and services.
- **Setup Commands**: Prepare and configure system commands needed for the setup.
- **Install TrinityCore Requirements**: Install all requirements necessary to run TrinityCore.
- **Install and Setup MySQL**: Complete installation and configuration of MySQL server.
- **Create Remote MySQL User**: Set up a MySQL user that can connect remotely.
- **Setup Firewall**: Configure firewall settings to secure the server.
- **Setup Linux Users**: Create necessary Linux users for server operations.
- **Install Fail2Ban**: Install Fail2Ban to enhance security by blocking suspicious activity.
- **Show Command List**: Display the available commands or functionalities of the script.

### Auth Server Functions
The following tasks pertain to the Auth server setup:

- **Close Authserver**: Shut down the Auth server if it is running.
- **Setup MySQL Database & Users**: Create databases and user accounts for the Auth server.
- **Pull and Setup Source**: Download and configure the source code for the Auth server.
- **Setup Authserver Config**: Configure the settings for the Auth server.
- **Setup Restarter**: Ensure the Auth server can automatically restart if it crashes.
- **Setup Crontab**: Schedule automated tasks using crontab for maintenance and backups.
- **Setup Alias**: Create command aliases for easier access to commonly used commands.
- **Start Authserver**: Launch the Auth server.

### Realm Server Functions
The following tasks are related to the Realm server setup:

- **Close Worldserver**: Shut down the World server if it is running.
- **Setup MySQL Database & Users**: Create databases and user accounts for the Realm server.
- **Pull and Setup Source**: Download and configure the source code for the World server.
- **Setup Worldserver Config**: Configure the settings for the World server.
- **Pull and Setup Database**: Download and configure the database for the World server.
- **Download 3.3.5a Client**: Fetch the necessary client files for version 3.3.5a.
- **Setup Client Tools**: Prepare tools necessary for managing the client.
- **Run Map/DBC Extractor**: Extract Map and DBC files for use in the game world.
- **Run VMap Extractor**: Extract VMap files for navigation and environment mapping.
- **Run Mmaps Extractor**: Extract MMap files for advanced pathfinding.
- **Setup Realmlist**: Configure the realmlist to connect game clients to the server.
- **Setup World Restarter Scripts**: Create scripts to automatically restart the World server.
- **Setup Misc Scripts**: Install any miscellaneous scripts required for server operations.
- **Setup Crontab**: Schedule automated tasks using crontab for maintenance and backups.
- **Setup Script Alias**: Create command aliases for easier access to commonly used commands.
- **Start Worldserver**: Launch the World server.

