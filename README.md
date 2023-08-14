# PiAutomation

## Setup the SD card:
```
Download the Raspberry Pi Imager:
https://downloads.raspberrypi.org/imager/imager_1.7.5.exe

After running the Raspberry Pi Imager press: CHOOSE OS
Select: Raspberry Pi OS (other), Raspberry Pi OS Lite (64-bit)

CHOOSE STORAGE:
Select your SD Card

Press on the gear/settings icon:
Check: Enable SSH
       Use password authentication

Check: Set username and password
       username: pi
       password: YourOwnPassword

If you plan on using wireless LAN / WLAN / Wifi do not enter any SSID or Password.
Read the instructions in the next section for usage of wireless LAN!

Check: Set locale settings
       Time zone: can be anything
       Keyboard layout: us

Persistant settings:
       Make sure Eject media when finished, is unchecked if you're planning on using wireless LAN!

Press the WRITE button and wait untill the Imager has written the OS.
When this is done close the Imager.

If you're not planning on using wireless LAN safely eject the SD card, setup your Pi and boot from the SD card.
Continue on the section: Setup the Pi
Otherwise read the section: Enabling wireless LAN
```  

## Enabling wireless LAN:
```
Open a text editor on your system and paste the following:
country=NL
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
network={
    ssid="YOURWIFINAME"
    psk="YOURWIFIPASSWORD!"
    key_mgmt=WPA-PSK
}

Change ssid= and psk= to your wireless LAN name and password.

Safe the file as wpa_supplicant.conf to the SD card labeled "boot" in your explorer.
Be aware to make sure there is no .txt extension in the filename!

You can now eject the SD card, setup your Pi and boot from the SD card.

```  

## Setup the Pi:
```
Find your Pi's IP address, you can use something like AngryIP for this.

SSH into your Pi with a program like MobaXTerm of Putty:
ssh pi@YOUR.RASPBERRY.IP.ADDRESS

Run the following command:
sudo nano /etc/ssh/sshd_config

Change the line: #PermitRootLogin no to: PermitRootLogin yes
Save and exit (ctrl+o & ctrl+x)

Run the following command:
sudo systemctl restart sshd

Run the following command:
sudo password

Enter your password twice and type: exit
You will be logged out of your session as the Pi user.

Reconnect but this time as root with the following command:
ssh root@YOUR.RASPBERRY.IP.ADDRESS

Continue to the next section: Running the installer.
``` 


## Running the installer:
```
wget https://raw.githubusercontent.com/Beeranco/PiAutomation/main/Installer.sh -O /tmp/installer.sh  
bash /tmp/installer.sh
```  
