##---------------##
#   Static-Vars   #
##---------------##

sed -i -e 's/magenta/blue/g' /etc/newt/palette
#OUTPUT='/dev/null'
OUTPUT='>/dev/null 2>&1'
APTMODE="debconf-apt-progress -- apt"
REPO=PiAutomation
GIT=https://raw.githubusercontent.com/Beeranco
BRANCHE=main


wget $GIT/$REPO/$BRANCHE/Domoticz/DomoService.conf
 wget https://raw.githubusercontent.com/Beeranco/PiAutomation/main/Domoticz/DomoService.conf  -O /etc/init.d/domoticz.sh

##---------##
#   Menu   #
##---------##

if (whiptail --title "Pi Automation" --yesno "This installer will turn your Raspberry Pi into a hub for home automation." 8 78); then
  INSTALL=yes
else
 INSTALL=no
fi

if [[ $INSTALL = no ]]; then
  whiptail --title "Pi Automation" --msgbox "Installation canceled!" 8 78
  clear
  exit
fi


##--------------------------##
#   Debian LXC Requirement   #
##--------------------------##

apt install whiptail curl -y -qq 2>/dev/null >/dev/null


##-------------##
#   Pre-Check   #
##-------------##

TERM=ansi whiptail --title "Pre-Check" --infobox "Please wait..." 8 78
sleep 3
ping -c 1 192.168.1.102 > /dev/null && HOSTUP=yes || HOSTUP=no

if [[ $HOSTUP = yes ]]; then
  echo > /dev/tcp/192.168.1.102/80 && echo 'Acquire::http::Proxy "http://192.168.1.102:80";'> /etc/apt/apt.conf.d/01prox || TERM=ansi whiptail --title "Pre-Check" --infobox "Not using an APT-Cache server" 8 78
  sleep 3
fi


##-----------##
#   Options   #
##-----------##

OPTIONS=$(whiptail --title "Configure Options" --checklist \
"What to install?" 10 105 5 \
"Domoticz" "Is a Home Automation System." ON \
"Node-RED" "Is a programming tool wiring hardware devices together." OFF \
"Zigbee2MQTT" "Supports various Zigbee adapters and a big bunch of devices." OFF \
"MQTT Broker" "Is a intermediary entity that enables MQTT clients to communicate." ON \
"Unattended Upgrades" "Is a system package that automaticly downloads security updates." ON 3>&1 1>&2 2>&3)


##---------------##
#   Configuring   #
##---------------##

TERM=ansi whiptail --title "Pi Automation" --infobox "Configuring Raspberry Pi" 8 78
sleep 3
echo "country=NL" >> /etc/wpa_supplicant/wpa_supplicant.conf
rfkill unblock wifi
sed -i -e 's/dtoverlay=vc4-kms-v3d/dtoverlay=vc4-fkms-v3d/g' /boot/config.txt
echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/01Recommends
echo 'APT::Install-Suggests "false";' >> /etc/apt/apt.conf.d/01Suggests.


##-----------------##
#   Pre-Installer   #
##-----------------##

(ls /dev/ttyACM0 >> /dev/null 2>&1) && USB=yes || USB=no
if [[ $USB == *"yes"* ]]; then
  whiptail --title "Error!" --msgbox "Remove the Zigbee USB first! Then you must hit OK to continue." 8 78
fi

TERM=ansi whiptail --title "Pi Automation" --infobox "Setup will begin with running updates and installing dependencies\nthis may take a while... Grab yourself a coffee!" 8 78
sleep 3
dphys-swapfile swapoff ; dphys-swapfile uninstall ; update-rc.d dphys-swapfile remove ; apt purge dphys-swapfile -qq -y
systemctl disable ModemManager

echo "python3-dev python3-pip" >> /tmp/install.list
if [[ $OPTIONS == *"Domoticz"* ]]; then
  echo "apt-utils git curl unzip wget sudo cron libudev-dev libsqlite3-0 libcurl4 libusb-0.1-4" >> /tmp/install.list
fi
if [[ $OPTIONS == *"Node-RED"* ]]; then
  echo "build-essential git curl" >> /tmp/install.list
  else
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  echo "nodejs" >> /tmp/install.list  
fi
if [[ $OPTIONS == *"Zigbee2MQTT"* ]]; then
  echo "git make g++ gcc" >> /tmp/install.list 
fi  
if [[ $OPTIONS == *"MQTT Broker"* ]]; then
  echo "mosquitto mosquitto-clients" >> /tmp/install.list
fi
if [[ $OPTIONS == *"Unattended Upgrades"* ]]; then
  echo "unattended-upgrades apt-listchanges" >> /tmp/install.list
fi

##-----------##
#   Updater   #
##-----------##

apt update
apt remove --purge manpages* p7zip* vim* pigz* strace* rng-tools* manpages* triggerhappy* -y
apt list --upgradeable 2>/dev/null | cut -d/ -f1 | grep -v Listing >> /tmp/install.list
echo "unattended-upgrades" /tmp/install.list
xargs < /tmp/install.list apt-get install -y
apt autoremove -y


##-------------##
#   Installer   #
##-------------##

if [[ $OPTIONS == *"Domoticz"* ]]; then
  mkdir -p /etc/domoticz/
  wget $GIT/$REPO/$BRANCHE/Domoticz/DomoSetup.conf -O /etc/domoticz/setupVars.conf
  
  mkdir -p /opt/domoticz/
  bash -c "$(curl -sSfL https://install.domoticz.com)"
  
  wget $GIT/$REPO/$BRANCHE/Domoticz/DomoService.conf  -O /etc/init.d/domoticz.sh
  chmod +x /etc/init.d/domoticz.sh
  update-rc.d domoticz.sh defaults
  systemctl start domoticz
fi

if [[ $OPTIONS == *"Node-RED"* ]]; then
  bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered) --confirm-root --confirm-install --skip-pi --node18 --no-init 
  systemctl enable nodered
  ###Test if nodered is not yet autostarted###
  systemctl status nodered

  cd /root/.node-red/
  npm install @node-red-contrib-themes/midnight-red
  cd ~
  wget $GIT/$REPO/$BRANCHE/Node-RED/NodeRED.conf -O /root/.node-red/settings.js
fi

if [[ $OPTIONS == *"Zigbee2MQTT"* ]]; then
  mkdir -p /opt/zigbee2mqtt/
  git clone --depth 1 https://github.com/Koenkk/zigbee2mqtt.git /opt/zigbee2mqtt
  wget $GIT/$REPO/$BRANCHE/Zigbee/zb2mqtt.config -O /opt/zigbee2mqtt/data/configuration.yaml
  cd /opt/zigbee2mqtt/
  npm ci /opt/zigbee2mqtt/
  npm audit fix
  
  npm start /opt/zigbee2mqtt/
  cd ~
  wget $GIT/$REPO/$BRANCHE/Zigbee/z2mqtt.service -O /etc/systemd/system/zigbee2mqtt.service
  systemctl daemon-reload
  systemctl enable zigbee2mqtt
fi

if [[ $OPTIONS == *"Unattended Upgrades"* ]]; then
  systemctl stop unattended-upgrades
  wget $GIT/$REPO/$BRANCHE/Unattended-Security-Updates/20auto-upgrades -O /etc/apt/apt.conf.d/20auto-upgrades
  wget $GIT/$REPO/$BRANCHE/Unattended-Security-Updates/50debian-unattended-upgrades -O /etc/apt/apt.conf.d/50unattended-upgrades
fi
