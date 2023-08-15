# PiAutomation

## Setup the SD card:
```
Insert your SD card

Download the Raspberry Pi Imager:
https://downloads.raspberrypi.org/imager/imager_1.7.5.exe

After running the Raspberry Pi Imager press:

CHOOSE OS
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
Read the instructions in the next section: Enabling wireless LAN.

Check: Set locale settings
       Time zone: can be anything
       Keyboard layout: us

Persistant settings:
       Make sure Eject media when finished, is unchecked if you're planning on using wireless LAN!

Press the WRITE button and wait untill the Imager has written the OS.
When this is done close the Imager.

If you're not planning on using wireless LAN:
safely eject the SD card, setup your Pi and boot from the SD card.

Continue on the section: Setup the Pi.
Otherwise read the section: Enabling wireless LAN.
```  

## Enabling wireless LAN:
```
IMPORTANT!!!
If you're planning to use 5GHz wireless LAN do NOT use the HDMI-1 port.
Read the FAQ section at the end of this manual to learn which port is HDMI-1

Close the Raspberry Pi Imager.

Open a text editor on your system and paste the following:
country=NL
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
network={
    ssid="YOURWIFINAME"
    psk="YOURWIFIPASSWORD"
    key_mgmt=WPA-PSK
}

Change ssid= and psk= to your wireless LAN name and password.

Save the file as wpa_supplicant.conf to the SD card labeled "bootfs" in your explorer.
Be aware to make sure there is no .txt extension in the filename!

You can now eject the SD card, setup your Pi and boot from the SD card.

Remember: you MUST use a LAN cable for the initial setup!!!
The installer will tell you when it's safe to unplug the LAN cable.

```  

## Setup the Pi:
```
Find your Pi's IP address, you can use something like AngryIP for this.

SSH into your Pi with a program like MobaXTerm of Putty:
ssh pi@YOUR.RASPBERRY.IP.ADDRESS

Run the following command:
sudo nano /etc/ssh/sshd_config

Change the line: #PermitRootLogin prohibit-password to: PermitRootLogin yes
Save and exit (ctrl+o & ctrl+x)

Run the following command:
sudo systemctl restart sshd

Run the following command:
sudo passwd

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


## FAQ:
```
### Why is this manual Windows only? ###
If you're a Linux user you must be smart or stupid enough to write to a SD card.
Otherwise: Google is your friend!
Hate me already for using Google?, you must be a real Linux user! DuckDuckGo is your best friend...




### Which Pi can I use? ###
This script is made and tested on a Raspberry Pi 4 2GB model.
A Pi 4 4GB or Pi 4 8GB would also work!

Older Pi's could experience slowdown and out of memory errors when running all of the
installer options due to limited resources and RAM logging (RAM logging explained below).

In the future the installer will calculate the total amount of RAM installed
and in the case of a Pi 4 1GB model disable the /tmp folder as RAM mounted




### Just use any SD card? ###
The simpel answer is no.
Definitly do not use cheap Target, Walmart, AliExpress like SD cards!

There are people that will tell you the "best" card in terms of performance,
that's just part of the story. Speed good, go fast is nice but more important in this use case:
reliability

The most reliable SD cards tested so far in order are:
SanDisk Extreme Pro
SanDisk Extreme
SanDisk Ultra
Samsung Evo Plus
Samsung Evo
Kingston




### 1GB of ram not good enough? ###
It's not the case of not being good enough, the Pi's all suffer from a major flaw:
the SD card.

Since this script is meant to transform your Pi into an automation hub that will
propably run 24/7 as a piece of infrastructure in your network failing is not an option.

Over time due to the writing of logs the SD card will wear out,
this means it wont be readable or writable just gone with all your data and programs.

It's always important no matter what you run to have backups,
but I also believe if there's a common problem that there must be a common solution!

The most commonly written to locations are /tmp and /var/log.
You've guessed it! /tmp is for all the temporary files the OS uses
and /var/log contains all the logs.

In this script we use an FSTAB mount entry that converts the /tmp folder from being
mounted to the SD card to being mounted to a slice of RAM in order to prevent
all these little write cycles to the SD card and wearing it out.

This also means that the more data is stored in the /tmp folder the more RAM usage you'll have
since /tmp is only "cleaned" on a shutdown or reboot,
and all these "little" files WILL add up in the amount of RAM usage.

The /var/log is managed by a little program called Log2RAM and does exactly what you'll think!
Storing all the logs in the RAM that is currently limited to use 256MB of space.

This program automaticly syncs every 24 hours to the SD card creating a backup in case of a power outage,
and saves to the SD card when you reboot or shutdown the system.
Only in the case of a sudden power loss the logs will be gone since RAM is volatile memory.
The logs that have been synced to the SD card in the last 24 hour period will be available.




### How to backup your SD card? ###
Well now I'm scared of losing all of my data! How to backup?

There's a little program called Win32DiskImager, Google it and install it.
When running Win32DiskImager select you SD card under Device and set the Image File to a path on your system.
For example: C:\Users\Administrator\Documents\PiBackup.img

Press Read and wait for it to finish! Eject the SD card and get your Pi running again!
In order to restore the image on the SD card after a failure or new SD card,
do the same thing again with Win32Disk imager but this time you press Write with the .img file selected.




### Why use a LAN cable when I'm planning on going wireless? ###
Since Debian or Pi I don't know what the wireless radio is disabled / blocked
untill you're running the command: rfkill unblock wifi

In order to run headless (without a monitor and keyboard) we need the
LAN cable to connect via SSH and run the script that also enables the wireless radio




### HDMI-0 or HDMI-1? You really think I what ports are where?! ###
Quick explanation: HDMI-0, closest to the USB-C / Power port!
HDMI-1, furthest away from the  USB-C / Power port!




### Why write a wpa_supplicant.conf? The Raspberry Pi Imager can setup wireless LAN? ###

Yes and no.
While the Raspberry Pi Imager does in fact write your SSID and Password to your Pi
even though you have selected your country code this will not be included in the
generated wpa_supplicant.conf.

This makes it impossible to enable the radio that makes your wireless LAN go beep-beep-boop.
In the example config for the wpa_supplicant.conf the country code is already configured,
with this your wireless LAN can and will go beep-beep-boop.




### Really? I can't even choose what HDMI port I use? ###
Well here's where things get complicated! For some arbitrary reason when using
5GHz wireless LAN and HDMI-1 the radio gets confused due to the HDMI cable
interfering with the radio signals.

This has been an issue on the Pi 4 since the release in 2019...
Users have reported the wireless LAN refusing to connect, connecting but dropping out
or barely working with a ping over 5000ms, so connecting via SSH won't even work.

There are some workarounds users have found by running resolutions other then 1920x1080,
like for example 1280x720, 2560x1440 or 1600x1200 and even going so far to change the
refresh rate or Hz on a 1080p signal to resuscitate the 5GHz radio.

But to be safe, use HDMI-0 if you're planning on using 5GHz wireless LAN
or when choosing 2.4GHz wireless lan cause this bug won't affect you and
you can do whatever with your HDMI ports!
```
