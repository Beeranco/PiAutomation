#!/bin/bash

##-------------##
#   Reminders   #
##-------------##

#Updating Domoticz every 6 monts
#Node-RED has a cycle of about every 3 months
#Zigbee2MQTT about every month
#OS updates every 2 weeks

##---------------##
#   Static Vars   #
##---------------##

DATE=$(date +"%m-%d-%Y")
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
  if [[ ! $(find "$DomoChk" -newermt "1 hours ago") ]]; then
    DomoUpd=true
    else
    DomoUpd=false
  fi
fi
if grep -q Node-RED "/etc/installedmodules"; then
  if [[ ! $(find "$NodeChk" -newermt "1 hours ago") ]]; then
    NodeUpd=true
    else
    NodeUpd=false
  fi
fi
if grep -q Zigbee2MQTT "/etc/installedmodules"; then
  if [[ ! $(find "$ZB2mChk" -newermt "1 hours ago") ]]; then
    ZB2mUpd=true
    else
    ZB2mUpd=false
  fi
fi
if [[ ! $(find "$osChk" -newermt "1 hours ago") ]]; then
  osUpd=true
  else
  osUpd=false
fi

echo "Testing output"
echo Domoticz $DomoUpd
echo NodeRed $NodeUpd
echo Zigbee $ZB2mUpd
echo Debian $OSUpd
echo ""


##-----------##
#   Updater   #
##-----------##

#echo "Test variables for updater"
#DomoUpd=false
#NodeUpd=false
#ZB2mUpd=false
#osUpd=false
#echo ""

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
    apt update
    apt upgrade -y
    apt autoremove -y
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

















##-----------##
#   Updater   #
##-----------##





if [[ $Domoticz == *"yes"* ]]; then

fi
if [[ $NodeRED == *"yes"* ]]; then

fi
if [[ $Zigbee2MQTT == *"yes"* ]]; then

fi
