# arma3-server
My old Arma3 script for running a server on linux. 

It can be used to create multi-instance or run headless client on the same machine as Arma3 server run on 1 core. 

I just cleaned it a bit.

## Requirement

You need to have : 
* a user named steamcmd
* steamcmd installed
* Arma3 server installed with steamcmd

### steamcmd user
```shell
adduser --disabled-login --gecos steamcmd steamcmd
```

### steamcmd installed
```shell
apt update
apt install software-properties-common -y
dpkg --add-architecture i386
apt update
apt install steamcmd -y
```
Install steamcmd with the steamcmd use

cf : https://developer.valvesoftware.com/wiki/SteamCMD#Debian

### Arma3 server installed with steamcmd
```shell
steamcmd
login <steam_user> <steam_password>
force_install_dir /home/steamcmd/Steam/steamapps/common/Arma3
app_update 233780 validate
workshop_download_item 107410 <mod_id>
```

## Installation

### Create a user named arma
```shell
adduser --disabled-login --no-create-home --gecos arma arma
usermod -g steamcmd arma
groupdel arma
```
All the next configuration will be done with steamcmd user

### Configuration
Place *server.cfg*, *basic.cfg*, *beserver.cfg* and *a3server.sh* on `/home/steamcmd/Steam/steamapps/common/Arma3` (or whatever the Arma3 installdir is)
Customize the cof file
* server.cfg : main server config
* basic.cfg : network config
* beserver.cfg : battleeye config

### Missions installation
You should put the missions in `/home/steamcmd/Steam/steamapps/common/Arma3/mpmissions`
add the missions on the server.cfg in `missionWhitelist[] = {};` without `.pbo`

### Install mods
Install the mods in `/home/steamcmd/Steam/steamapps/common/Arma3/mods`

Install the server mods in `/home/steamcmd/Steam/steamapps/common/Arma3/servermods`

The location can be changed on *a3server.sh*

You can prefix the name of each mods file with a number in order to load the in a specific order.

### a3server config
Be sure that the script can be executed by arma user
```shell
chown arma:steamcmd a3server.sh
chmod u+x a3server.sh
```

You can customize the variables on this script

At this point the server should be able to run. Try to start it with `a3server.sh start` Check the status with `a3server.sh status` and check that there is a log file

### Service
Put *arma3.service* in `/etc/systemd/system/`
Change the path in the file if Arma3 is not installed in `/home/steamcmd/Steam/steamapps/common/Arma3/`

reload your services and enable it if you whant arma to autostart when the server start
```shell
systemctl daemon-reload
systemctl enable arma3
```

## More tips

Don't forget to setup a logrotate.
Arma server need to be restarted frequently if you run a persistant mission like Antistasi or Exile. You can setup a cron or systemd timer to restart it.