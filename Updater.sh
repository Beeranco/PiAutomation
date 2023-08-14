#!/bin/bash

##---------------##
#   Static Vars   #
##---------------##

OUTPUT='/dev/null'
APTMODE="debconf-apt-progress -- apt"
PKGM="$APTMODE"
PKGUD="$PKGM update"
PKGUP="$PKGM upgrade -y"
PKGI="${PKGM} install -y"
PKRM="$PKGM remove --purge -y"
PKARM="$PKGM autoremove -y"
DATE=$(date "+%d-%m-%Y")
NAME=$(<"/etc/username")
DomoChk=/opt/backups/timestamps/Domoticz.update
NodeChk=/opt/backups/timestamps/NodeRED.update
ZB2mChk=/opt/backups/timestamps/Zigbee2MQTT.update
osChk=/opt/backups/timestamps/OS.update


##--------##
#   Menu   #
##--------##

if (whiptail --title "Welcome $NAME" --yesno "This script will update and backup your packages." 8 78); then
  CONTINUE=yes
else
  CONTINUE=no
fi

if [[ $CONTINUE == no ]]; then
  whiptail --title "Updater" --msgbox "Update canceled!" 8 78
  clear
  exit
fi


##-------------##
#   Pre-Check   #
##-------------##

if grep -q Domoticz "/etc/installedmodules"; then
  if [[ ! $(find "$DomoChk" -newermt "4368 hours ago") ]]; then
    DomoUpd=true
    else
    DomoUpd=false
  fi
fi
if grep -q Node-RED "/etc/installedmodules"; then
  if [[ ! $(find "$NodeChk" -newermt "2184 hours ago") ]]; then
    NodeUpd=true
    else
    NodeUpd=false
  fi
fi
if grep -q Zigbee2MQTT "/etc/installedmodules"; then
  if [[ ! $(find "$ZB2mChk" -newermt "720 hours ago") ]]; then
    ZB2mUpd=true
    else
    ZB2mUpd=false
  fi
fi
if [[ ! $(find "$osChk" -newermt "336 hours ago") ]]; then
  osUpd=true
  else
  osUpd=false
fi


##-----------##
#   Updater   #
##-----------##

if [[ $DomoUpd == false ]] && [[ $NodeUpd == false ]] && [[ $ZB2mUpd == false ]] && [[ $osUpd == false ]]; then
  whiptail --title "Updater" --msgbox "All packages have been updated recently enough, you're up-to-date! \nThank you $NAME for checking anyway :)" 8 78
  exit
else
    if [[ $DomoUpd == true ]]; then
    TERM=ansi whiptail --title "Updater" --infobox "Starting updater for Domoticz" 8 78
    echo "Updated on: $DATE" > /opt/backups/timestamps/Domoticz.update
    sleep 3
    mkdir -p /opt/backups/Domoticz
    systemctl stop domoticz
    cp /opt/domoticz/domoticz.db /opt/backups/Domoticz/domoticz.db
    bash /opt/domoticz/updaterelease
    systemctl start domoticz
    fi
    if [[ $NodeUpd == true ]]; then
    TERM=ansi whiptail --title "Updater" --infobox "Starting updater for Node-RED" 8 78
    echo "Updated on: $DATE" > /opt/backups/timestamps/NodeRED.update
    sleep 3
    mkdir -p /opt/backups/Node-RED
    systemctl stop nodered
    cp /root/.node-red/settings.js /opt/backups/Node-RED/settings.js
    cp /root/.node-red/flows.json /opt/backups/Node-RED/flows.json
    npm install -g --unsafe-perm node-red
    systemctl start nodered
    fi
    if [[ $ZB2mUpd == true ]]; then
    TERM=ansi whiptail --title "Updater" --infobox "Starting updater for Zigbee2MQTT" 8 78
    echo "Updated on: $DATE" > /opt/backups/timestamps/Zigbee2MQTT.update
    sleep 3
    mkdir -p /opt/backups/Zigbee2MQTT
    systemctl stop zigbee2mqtt
    cp /opt/zigbee2mqtt/data/configuration.yaml /opt/backups/Zigbee2MQTT/configuration.yaml
    cp /opt/zigbee2mqtt/data/coordinator_backup.json /opt/backups/Zigbee2MQTT/coordinator_backup.json
    cp /opt/zigbee2mqtt/data/database.db /opt/backups/Zigbee2MQTT/database.db
    cd /opt/zigbee2mqtt
    git pull
    npm ci
    cd ~
    systemctl start zigbee2mqtt
    fi
    if [[ $osUpd == true ]]; then
    TERM=ansi whiptail --title "Updater" --infobox "Starting updater for Debian" 8 78
    REBOOT=yes
    echo "Updated on: $DATE" > /opt/backups/timestamps/OS.update
    sleep 3
    $PKGUD
    $PKGUP
    $PKARM
    fi
fi


##-------------##
#   Finishing   #
##-------------##

if [[ $REBOOT == yes ]]; then
  if (whiptail --title "Updater" --yesno "Setup has updated Debian, it's strongly recommended to reboot the system \nDo you wish to reboot now?" 8 78); then
    reboot
  else
    TERM=ansi whiptail --title "Updater" --infobox "The updater is finished, please reboot me a soons as possible $NAME." 8 78
    sleep 5
    clear
    exit
  fi
fi

TERM=ansi whiptail --title "Updater" --infobox "Thank you for using the updater $NAME! Hope to see you soon?" 8 78
sleep 5
clear
exit
