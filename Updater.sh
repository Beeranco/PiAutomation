#!/bin/bash

if (whiptail --title "Updater" --yesno "This script will update and backup your packages." 8 78); then
  UPDATE=yes
else
  UPDATE=no
fi

if [[ $UPDATE == no ]]; then
  whiptail --title "Updater" --msgbox "Update canceled!" 8 78
  clear
  exit
fi

if grep -q Domoticz "/etc/installedmodules"; then
  if (whiptail --title "Updater" --yesno "Update Domoticz?" 8 78); then
    Domoticz=yes
    else
    echo ""
  fi
fi

if grep -q Node-RED "/etc/installedmodules"; then
  if (whiptail --title "Updater" --yesno "Update Node-RED?" 8 78); then
    NodeRED=yes
    else
    echo ""
  fi
fi

if grep -q Zigbee2MQTT "/etc/installedmodules"; then
  if (whiptail --title "Updater" --yesno "Update Zigbee2MQTT?" 8 78); then
    Zigbee2MQTT=yes
    else
    echo ""
  fi
fi

apt update
apt upgrade -y

if [[ $Domoticz == *"yes"* ]]; then
  mkdir -p /opt/backups/Domoticz
  systemctl stop domoticz
  cp /opt/domoticz/domoticz.db /opt/backups/Domoticz/domoticz.db
  bash /opt/domoticz/updaterelease
  systemctl start domoticz
fi
if [[ $NodeRED == *"yes"* ]]; then
  mkdir -p /opt/backups/Node-RED
  systemctl stop nodered
  cp /root/.node-red/settings.js /opt/backups/Node-RED/settings.js
  cp /root/.node-red/flows.json /opt/backups/Node-RED/flows.json
  npm install -g --unsafe-perm node-red
  systemctl start nodered
fi
if [[ $Zigbee2MQTT == *"yes"* ]]; then
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
