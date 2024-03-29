#!/bin/bash

##-------------##
#   Test Vars   #
##-------------##

AGREE=yes
SKIPinfo=yes
SKIPoptions=yes
SKIPhomer=yes

if [[ $SKIPoptions == "yes" ]]; then
OPTIONS='"Domoticz" "Zigbee2MQTT" "Unattended-Upgrades" "Monitor-Service" "Homer"'
fi
if [[ $SKIPhomer == "yes" ]]; then
ISP=Ziggo
isp=$(echo "$ISP" | tr '[:upper:]' '[:lower:]')
ROUTE=$(ip route show default | awk '/default/ {print $3}')
fi

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
CORES=`nproc --all`
REPO=PiAutomation
GIT=https://raw.githubusercontent.com/Beeranco
BRANCH=main


##---------------##
#   Dependencies  #
##---------------##

$PKGI curl wget whiptail


##----------------------------##
#   Check if Pi is compatible  #
##----------------------------##

wget $GIT/$REPO/$BRANCH/RasPi-Config/Requirements.sh -O /tmp/Requirements.sh
source /tmp/Requirements.sh

##-----------##
#   Check OS  #
##-----------##

dist=$(grep --color=never -Po "^ID=\K.*" "/etc/os-release")
dist_ver=$(grep --color=never -Po "^VERSION_ID=\K.*" "/etc/os-release")
dist_ver="${dist_ver//\"}"

if [[ $dist != debian ]]; then
  whiptail --title "Error" --msgbox "Only Debian is supported!" 8 78
  clear
  exit
fi
if [[ $dist_ver != 11 ]]; then
  if (whiptail --title "Warning" --yesno "This script is tested on Debian 11, use it on your own risk. \nYou're currently running Debian $dist_ver! \n\nContinue anyway?" 10 78); then
    echo ""
  else
    clear
    exit
  fi
fi


##---------##
#   Menu   #
##---------##

if [[ $AGREE != "yes" ]]; then
  if (whiptail --title "Pi Automation" --yesno "This installer will turn your Raspberry Pi into a hub for home automation." 8 78); then
    INSTALL=yes
  else
    INSTALL=no
  fi
fi
if [[ $INSTALL == no ]]; then
  whiptail --title "Pi Automation" --msgbox "Installation canceled!" 8 78
  clear
  exit
fi

if [[ $SKIPinfo != "yes" ]]; then
NAME=$(whiptail --nocancel --inputbox "What is your name?" 8 39 John --title "Welcome" 3>&1 1>&2 2>&3)
HOST=$(whiptail --nocancel --inputbox "What is the name of this machine?\n(only az-AZ 0-9 characters are allowed)" 8 43 PiMation --title "Welcome $NAME!" 3>&1 1>&2 2>&3)
HOST=$(echo $HOST | tr -dc '[:alnum:]\n\r')
else
  NAME=Tester
  HOST=Admin
fi

##-------------##
#   Pre-Check   #
##-------------##

TERM=ansi whiptail --title "Pre-Check" --infobox "Please wait..." 8 78
sleep 3

TZDATA=`timedatectl`
ping -c 1 192.168.1.102 > /dev/null && HOSTUP=yes || HOSTUP=no
if [[ $HOSTUP == yes ]]; then
  echo > /dev/tcp/192.168.1.102/80 && echo 'Acquire::http::Proxy "http://192.168.1.102:80";'> /etc/apt/apt.conf.d/01prox || TERM=ansi whiptail --title "Pre-Check" --infobox "Not using an APT-Cache server" 8 78
  sleep 3
fi


##-----------##
#   Options   #
##-----------##

if [[ $SKIPoptions != "yes" ]]; then
  OPTIONS=$(whiptail --title "Configure Options" --checklist \
  "What to install?" 12 113 6 \
  "Domoticz" "Is a Home Automation System." ON \
  "Node-RED" "Is a programming tool wiring hardware devices together." OFF \
  "Zigbee2MQTT" "Supports various Zigbee adapters and a big bunch of devices." OFF \
  "Unattended-Upgrades" "Is a system package that automaticly downloads security updates." ON \
  "Homer" "Is a dashboard with Google and quick links to your installed services." OFF \
  "Monitor-Service" "Autologin the Pi user to show system and service statuses. (usefull with TFT)" OFF 3>&1 1>&2 2>&3)
fi

if [[ $SKIPhomer != "yes" ]]; then
  if [[ $OPTIONS == *"Homer"* ]]; then
    ISP=$(whiptail --title "Configure Options" --radiolist \
    "Who is your ISP?" 12 60 4 \
    "Ziggo" "Is my internet provider." ON \
    "KPN" "Is my internet provider." OFF \
    "T-Mobile" "Is my internet provider." OFF \
    "Other" "I don't see my provider listed here." OFF 3>&1 1>&2 2>&3)
  fi
fi

##-------------------##
#   Pre-Configuring   #
##-------------------##

TERM=ansi whiptail --title "Pi Automation" --infobox "Preparing the Raspberry Pi." 8 78
sleep 3

hostnamectl set-hostname $HOST
sed -i '/raspberrypi/d' /etc/hosts
echo "127.0.1.1      $HOST" >> /etc/hosts

if grep -q "ssid=" /etc/wpa_supplicant/wpa_supplicant.conf
  then {
  echo 0; sleep 1; rfkill unblock wifi; echo 20;
  sleep 3; systemctl enable wpa_supplicant &> /dev/null && systemctl restart wpa_supplicant &> /dev/null; echo 40;
  sleep 3; ip link set wlan0 up; echo 60; while true; do ping -I wlan0 -c1 1.1.1.1 &> /dev/null && break; done; echo 80;
  sleep 3; echo 100; sleep 1; } | whiptail --title "Pi Automation" --gauge "Configuring wireless LAN. Please wait..." 6 70 0
  IP=`hostname -I` && IP=$(echo $IP | cut -d' ' -f2,3)
  else
  echo "country=NL" >> /etc/wpa_supplicant/wpa_supplicant.conf
  IP=`hostname -I` && IP=$(echo $IP | cut -d ' ' -f 1)
  rfkill unblock wifi
fi

if grep -q "Amsterdam" <<< "$TZDATA"; then
    echo "Timezone properly configured"
    else
    timedatectl set-timezone Europe/Amsterdam
fi

rm /etc/motd
rm /etc/update-motd.d/10-uname

echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/01Recommends
echo 'APT::Install-Suggests "false";' >> /etc/apt/apt.conf.d/01Suggests

if [[ $OPTIONS == *"Monitor-Service"* ]]; then
  wget $GIT/$REPO/$BRANCH/RasPi-Config/autologin -O /etc/systemd/system/getty@tty1.service.d/autologin.conf
  wget $GIT/$REPO/$BRANCH/RasPi-Config/monitor.service -O /etc/monitor.service
  echo "" >> /home/pi/.profile
  echo "# show Monitor on autologon" >> /home/pi/.profile
  echo "sudo bash /etc/monitor.service 2>/dev/null" >> /home/pi/.profile
  systemctl daemon-reload
  systemctl restart getty@tty1.service
fi


##-----------------##
#   Pre-Installer   #
##-----------------##

TERM=ansi whiptail --title "Pi Automation" --infobox "Preparing required packages." 8 78
sleep 3

(ls /dev/ttyACM0 >> /dev/null 2>&1) && USB=yes || USB=no
if [[ $USB == *"yes"* ]]; then
  whiptail --title "Error!" --msgbox "Remove the Zigbee Dongle first! After removal press OK to continue." 8 78
fi

TERM=ansi whiptail --title "Pi Automation" --infobox "Setup will begin with running updates and installing dependencies\nthis may take a while... Grab yourself a coffee!" 8 78
sleep 3
dphys-swapfile swapoff ; dphys-swapfile uninstall ; update-rc.d dphys-swapfile remove
systemctl disable ModemManager

echo "python3-dev python3-pip" >> /tmp/install.list
if [[ $OPTIONS == *"Domoticz"* ]]; then
  echo "apt-utils git curl unzip wget sudo cron libudev-dev libsqlite3-0 libcurl4 libusb-0.1-4" >> /tmp/install.list
fi
if [[ $OPTIONS == *"Node-RED"* ]]; then
  echo "build-essential git curl mosquitto mosquitto-clients" >> /tmp/install.list
fi
if [[ $OPTIONS == *"Zigbee2MQTT"* ]]; then
  echo "git make g++ gcc mosquitto mosquitto-clients" >> /tmp/install.list
  if [[ $OPTIONS != *"Node-RED"* ]]; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    echo "nodejs" >> /tmp/install.list
  fi
fi
if [[ $OPTIONS == *"Unattended-Upgrades"* ]]; then
  echo "unattended-upgrades apt-listchanges" >> /tmp/install.list
fi
if [[ $OPTIONS == *"Homer"* ]]; then
  echo "nginx unzip" >> /tmp/install.list
fi

##-----------##
#   Updater   #
##-----------##

TERM=ansi whiptail --title "Pi Automation" --infobox "Updating packages." 8 78
sleep 3

$PKGUD
apt list --upgradeable 2>/dev/null | cut -d/ -f1 | grep -v Listing >> /tmp/install.list
echo "ufw" >> /tmp/install.list
#Tools required to build and compile rsync 3.2.7.
echo "gcc g++ gawk autoconf automake python3-cmarkgfm libssl-dev attr libxxhash-dev libattr1-dev liblz4-dev libzstd-dev acl libacl1-dev" >> /tmp/install.list
xargs < /tmp/install.list xargs $PKGI


##-------------##
#   Installer   #
##-------------##

TERM=ansi whiptail --title "Pi Automation" --infobox "Installing packages." 8 78
sleep 3

TERM=ansi whiptail --title "Pi Automation" --infobox "Building, compiling and installing rsync 3.2.7." 8 78
sleep 3
#Build and compile rsync 3.2.7 to prevent rsync errors.
#This is a bug in the repository that supplies rsync version 3.2.3.
wget https://download.samba.org/pub/rsync/src/rsync-3.2.7.tar.gz -O /tmp/rsync-3.2.7.tar.gz
tar -vxf /tmp/rsync-3.2.7.tar.gz -C /tmp/
cd /tmp/rsync-3.2.7/
./configure
make -j $CORES
make install
cd ~

if [[ $OPTIONS == *"Node-RED"* ]]; then
  TERM=ansi whiptail --title "Pi Automation" --infobox "Installing Node-RED." 8 78
  sleep 3
  bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered) --confirm-root --confirm-install --skip-pi --node18 --no-init 
  systemctl enable nodered
  cd /root/.node-red/
  npm install @node-red-contrib-themes/midnight-red
  cd ~
  wget $GIT/$REPO/$BRANCH/Node-RED/NodeRED.conf -O /root/.node-red/settings.js
fi
if [[ $OPTIONS == *"Zigbee2MQTT"* ]]; then
  TERM=ansi whiptail --title "Pi Automation" --infobox "Installing Zigbee2MQTT." 8 78
  sleep 3
  mkdir -p /opt/zigbee2mqtt/
  git clone --depth 1 https://github.com/Koenkk/zigbee2mqtt.git /opt/zigbee2mqtt
  wget $GIT/$REPO/$BRANCH/Zigbee/zb2mqtt.config -O /opt/zigbee2mqtt/data/configuration.yaml
  cd /opt/zigbee2mqtt/
  npm ci /opt/zigbee2mqtt/
  npm install -g npm@latest
  npm audit fix
  npm start /opt/zigbee2mqtt/
  cd ~
  wget $GIT/$REPO/$BRANCH/Zigbee/z2mqtt.service -O /etc/systemd/system/zigbee2mqtt.service
  systemctl daemon-reload
  systemctl enable zigbee2mqtt
fi
if [[ $OPTIONS == *"Homer"* ]]; then
  TERM=ansi whiptail --title "Pi Automation" --infobox "Installing Homer." 8 78
  sleep 3
  rm /etc/nginx/sites/enabled/default
  wget $GIT/$REPO/$BRANCH/Homer/site.conf -O /etc/nginx/sites-enabled/dashboard
  wget $GIT/$REPO/$BRANCH/Homer/dashboard.zip -O /tmp/dashboard.zip
  mkdir -p /var/www/html
  mkdir -p /var/log/nginx/
  systemctl enable --now nginx
  rm /etc/nginx/sites-enabled/default
  systemctl stop nginx
  unzip /tmp/dashboard.zip -d /var/www/html/
fi
if [[ $OPTIONS == *"Domoticz"* ]]; then
  TERM=ansi whiptail --title "Pi Automation" --msgbox "In the next dialog tell Domoticz to update.\nDo NOT select reconfigure!\n\nPress OK to continue." 10 78
  mkdir -p /etc/domoticz/
  wget $GIT/$REPO/$BRANCH/Domoticz/DomoSetup.conf -O /etc/domoticz/setupVars.conf
  mkdir -p /opt/domoticz/
  bash -c "$(curl -sSfL https://install.domoticz.com)"
  wget $GIT/$REPO/$BRANCH/Domoticz/DomoService.conf  -O /etc/init.d/domoticz.sh
  chmod +x /etc/init.d/domoticz.sh
  update-rc.d domoticz.sh defaults
  systemctl start domoticz
fi


##---------------##
#   Configuring   #
##---------------##

TERM=ansi whiptail --title "Pi Automation" --infobox "Configuring system." 8 78
sleep 3

TERM=ansi whiptail --title "Pi Automation" --infobox "Disabling IPv6." 8 78
sleep 3
echo "" >> /etc/sysctl.conf
echo "#Disable IPv6" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf

sed -i 's/IPV6=yes/IPV6=no/g' /etc/default/ufw

TERM=ansi whiptail --title "Pi Automation" --infobox "Configuring Firewall." 8 78
sleep 3
ufw default deny incoming
ufw default allow outgoing

if [[ $OPTIONS == *"Domoticz"* ]]; then
  ufw allow 8080/tcp
fi
if [[ $OPTIONS == *"Zigbee2MQTT"* ]]; then
  ufw allow 5002/tcp
  ufw allow 1883/tcp
  ufw allow 1883/udp
fi
if [[ $OPTIONS == *"Node-RED"* ]]; then
  ufw allow 1880/tcp
  ufw allow 1880/udp
fi
if [[ $OPTIONS == *"Homer"* ]]; then
  ufw allow 80/tcp
fi

ufw limit 22/tcp
echo "y" | ufw enable

if [[ $OPTIONS == *"Unattended-Upgrades"* ]]; then
  TERM=ansi whiptail --title "Pi Automation" --infobox "Configuring Unattended-Upgrades." 8 78
  sleep 3
  systemctl stop unattended-upgrades
  wget $GIT/$REPO/$BRANCH/Unattended-Security-Updates/20auto-upgrades -O /etc/apt/apt.conf.d/20auto-upgrades
  wget $GIT/$REPO/$BRANCH/Unattended-Security-Updates/50debian-unattended-upgrades -O /etc/apt/apt.conf.d/50unattended-upgrades
fi

TERM=ansi whiptail --title "Pi Automation" --infobox "Configuring Homer." 8 78
sleep 3
if [[ $OPTIONS == *"Homer"* ]]; then
 if [[ ! -z "$ISP" ]]; then
   isp=$(echo "$ISP" | tr '[:upper:]' '[:lower:]')
   ROUTE=$(ip route show default | awk '/default/ {print $3}')
   echo "" >> /var/www/html/assets/config.yml
   echo "  - name: "Network"" >> /var/www/html/assets/config.yml
   echo "    icon: "fa-solid fa-server"" >> /var/www/html/assets/config.yml
   echo "    items:" >> /var/www/html/assets/config.yml
   echo "      - name: "PROVIDER Modem"" >> /var/www/html/assets/config.yml
   echo "        logo: "assets/tools/provider.png"" >> /var/www/html/assets/config.yml
   echo "        tag: "provider, network"" >> /var/www/html/assets/config.yml
   echo "        tagstyle: "is-primary"" >> /var/www/html/assets/config.yml
   echo "        url: "GATEWAY"" >> /var/www/html/assets/config.yml
   echo "        target: "_blank"" >> /var/www/html/assets/config.yml
   sed -i "s/PROVIDER/$ISP/g" /var/www/html/assets/config.yml
   sed -i "s/provider/$isp/g" /var/www/html/assets/config.yml
   sed -i "s/GATEWAY/http\:\/\/$ROUTE/g" /var/www/html/assets/config.yml
  fi
fi

if [[ $OPTIONS == *"Homer"* ]]; then
  if [[ $OPTIONS == *"Domoticz"* ]] || [[ $OPTIONS == *"Node-RED"* ]]  || [[ $OPTIONS == *"Zigbee2MQTT"* ]]; then
    echo "" >> /var/www/html/assets/config.yml
    echo "  - name: "Automation"" >> /var/www/html/assets/config.yml
    echo "    icon: "fa-solid fa-house-signal"" >> /var/www/html/assets/config.yml
    echo "    items:" >> /var/www/html/assets/config.yml
    if [[ $OPTIONS == *"Domoticz"* ]]; then
      echo "      - name: "Domoticz"" >> /var/www/html/assets/config.yml
      echo "        logo: "assets/tools/domoticz.png"" >> /var/www/html/assets/config.yml
      echo "        tag: "automation, smarthome, tools"" >> /var/www/html/assets/config.yml
      echo "        tagstyle: "is-info"" >> /var/www/html/assets/config.yml
      echo "        url: "http://IP:8080/"" >> /var/www/html/assets/config.yml
      echo "        target: "_blank"" >> /var/www/html/assets/config.yml
      sed -i "s/IP/$IP/g" /var/www/html/assets/config.yml
    fi
    if [[ $OPTIONS == *"Node-RED"* ]]; then
      echo "      - name: "NodeRED"" >> /var/www/html/assets/config.yml
      echo "        logo: "assets/tools/nodered.png"" >> /var/www/html/assets/config.yml
      echo "        tag: "automation, smarthome, tools"" >> /var/www/html/assets/config.yml
      echo "        tagstyle: "is-info"" >> /var/www/html/assets/config.yml
      echo "        url: "http://IP:1880/"" >> /var/www/html/assets/config.yml
      echo "        target: "_blank"" >> /var/www/html/assets/config.yml
      sed -i "s/IP/$IP/g" /var/www/html/assets/config.yml
    fi
    if [[ $OPTIONS == *"Zigbee2MQTT"* ]]; then
      echo "      - name: "Zigbee2MQTT"" >> /var/www/html/assets/config.yml
      echo "        logo: "assets/tools/zigbee2mqtt.png"" >> /var/www/html/assets/config.yml
      echo "        tag: "automation, smarthome, tools"" >> /var/www/html/assets/config.yml
      echo "        tagstyle: "is-info"" >> /var/www/html/assets/config.yml
      echo "        url: "http://IP:5002/"" >> /var/www/html/assets/config.yml
      echo "        target: "_blank" " >> /var/www/html/assets/config.yml
      sed -i "s/IP/$IP/g" /var/www/html/assets/config.yml
    fi
  fi
fi

##-----------------##
#   Optimizing Pi   #
##-----------------##

TERM=ansi whiptail --title "Pi Automation" --infobox "Optimizing Raspberry Pi." 8 78
sleep 3

echo "" >> /boot/config.txt
echo "#Reduce allocated GPU Memory since we're running headless" >> /boot/config.txt
echo "gpu_mem=16" >> /boot/config.txt

TERM=ansi whiptail --title "Pi Automation" --infobox "Optimizing SD Card." 8 78
sleep 3
if [[ $PI4 == "yes" ]] && [[ $UNSAFE == "no" ]]; then
  echo "" >> /etc/fstab
  echo "#Mounting /tmp folder to RAM so it reduces SD Card wear" >> /etc/fstab
  echo "tmpfs /tmp tmpfs defaults,noatime,nosuid 0 0" >> /etc/fstab
fi

curl -L https://github.com/azlux/log2ram/archive/master.tar.gz -o /tmp/log2ram.tar.gz
tar zxfv /tmp/log2ram.tar.gz -C /tmp/
cd /tmp/log2ram-master/
chmod +x install.sh && sudo ./install.sh
sed -i 's/apache2.service/nginx.service/g' /etc/systemd/system/log2ram.service
systemctl daemon-reload
cd ~

if [[ $UNSAFE == "no" ]]; then
  sed -i -e 's/SIZE=128M/SIZE=256M/g' /etc/log2ram.conf
fi

sed -i -e 's/MAIL=true/MAIL=false/g' /etc/log2ram.conf
journalctl --vacuum-size=32M
systemctl restart systemd-journald
rm -rf /var/log/journal

if [[ $PI4 == "no" ]]; then
  sed -i -e 's/# CPU_DEFAULT_GOVERNOR="ondemand"/CPU_DEFAULT_GOVERNOR="performance"/g' /etc/default/cpu_governor
  else
  sed -i -e 's/# CPU_DEFAULT_GOVERNOR="ondemand"/CPU_DEFAULT_GOVERNOR="conservative"/g' /etc/default/cpu_governor
fi


##--------------##
#   Store Vars   #
##--------------##

echo $NAME > /etc/username
echo $OPTIONS > /etc/installedmodules
sed -i 's/\s\+/\n/g' /etc/installedmodules
sed -i 's/\"//g' /etc/installedmodules


##---------------##
#   Cleaning up   #
##---------------##

TERM=ansi whiptail --title "Pi Automation" --infobox "Cleaning up unnecessary packages." 8 78
sleep 3

$PKRM dphys-swapfile* manpages* p7zip* vim* pigz* strace* rng-tools* manpages* triggerhappy* gawk python3-cmarkgfm attr libxxhash-dev libattr1-dev liblz4-dev libzstd-dev acl libacl1-dev
$PKARM

##-------------##
#   Finishing   #
##-------------##

TERM=ansi whiptail --title "Pi Automation" --infobox "Finishing." 8 78
sleep 3

wget $GIT/$REPO/$BRANCH/Updater.sh -O /opt/updater.sh
wget $GIT/$REPO/$BRANCH/MOTD/greetings.sh -O /etc/profile.d/greeting.sh
sed -i -e "s/%name%/$NAME/g" /etc/profile.d/greeting.sh

mkdir -p /opt/backups/timestamps/
echo "Installed on: $DATE" > /opt/backups/timestamps/OS.update

if [[ $OPTIONS == *"Zigbee2MQTT"* ]]; then
whiptail --title "Done!" --msgbox "Please insert the Zigbee Dongle into a USB 2.0 port. Press OK to continue." 8 78
fi

if [[ $OPTIONS == *"Homer"* ]]; then
  whiptail --title "Info" --msgbox "After a reboot your dashboard and all configured services are available on:\nhttp://$IP" 8 79
  else
  if grep -q Domoticz "/etc/installedmodules"; then
    echo "Installed on: $DATE" > /opt/backups/timestamps/Domoticz.update
    whiptail --title "Remember" --msgbox "After a reboot Domoticz is accessible on:\nhttp://$IP:8080" 8 78
  fi
  if grep -q Node-RED "/etc/installedmodules"; then
    echo "Installed on: $DATE" > /opt/backups/timestamps/NodeRED.update
    whiptail --title "Remember" --msgbox "After a reboot Node-RED is accessible on:\nhttp://$IP:1880" 8 78
  fi
  if grep -q Zigbee2MQTT "/etc/installedmodules"; then
    echo "Installed on: $DATE" > /opt/backups/timestamps/Zigbee2MQTT.update
    whiptail --title "Remember" --msgbox "After a reboot Zigbee2MQTT is accessible on:\nhttp://$IP:5002" 8 78
  fi
fi

if grep -q "ssid=" /etc/wpa_supplicant/wpa_supplicant.conf
then
  whiptail --title "Done!" --msgbox "The Raspberry Pi will shutdown,\nplease remove the LAN cable before starting up again.\n\nPress OK to continue." 10 78
  shutdown now
else
  whiptail --title "Done!" --msgbox "The Raspberry Pi will reboot. Press OK to continue." 8 78
  reboot
fi
