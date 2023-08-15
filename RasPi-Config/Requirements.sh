PiRevision=`grep "Revision" /proc/cpuinfo` && PiRevision=$(echo $PiRevision | cut -f 2 -d ':' | cut -d' ' -f2,3)
#Test Variables
#PiRevision=a02082 #3B
#PiRevision=a020d3 #3B+
PiRevision=a03111 #4 1GB
#PiRevision=c03111 #4 4GB
#PiRevision=d03114 #4 8GB
#PiRevision=aaaaaa #Unsupported

if [[ $PiRevision == "a02082" ]] || [[ $PiRevision == "a22082" ]]; then
  Model="Raspberry Pi 3 Model B"
  Pi="Pi 3B"
elif [[ $PiRevision == "a020d3" ]]; then
  Model="Raspberry Pi 3 Model B+"
  Pi="Pi 3B+"
elif [[ $PiRevision == "a03111" ]]; then
  Model="Raspberry Pi 4 1GB"
  Pi="Pi 4 1GB"
elif [[ $PiRevision == "b03111" ]] || [[ $PiRevision == "b03112" ]] || [[ $PiRevision == "b03114" ]]; then
  Model="Raspberry Pi 4 2GB"
  Pi="Pi 4 2GB"
elif [[ $PiRevision == "c03111" ]] || [[ $PiRevision == "c03112" ]] || [[ $PiRevision == "c03114" ]]; then
  Model="Raspberry Pi 4 4GB"
  Pi="Pi 4 4GB"
elif [[ $PiRevision == "d03114" ]]; then
  Model="Raspberry Pi 4 8GB"
  Pi="Pi 4 8GB"
else
  Model="not supported!"
fi

if [[ $PiRevision == "a02082" ]] || [[ $PiRevision == "a22082" ]] || [[ $PiRevision == "a020d3" ]]; then
  if (whiptail --title "Warning" --yesno "You're running a $Model,\nthis script is tested for a Raspberry Pi 4 with at least 2GB memory.\n\nThe $Pi can lack the power or resources to run all of the installer options.\nIf you continue mounting the /tmp to RAM will be disabled.\n\nContinue anyway?" 13 83); then
    UNSAFE=yes
    PI4=no
  else
    clear
    exit
  fi
elif [[ $PiRevision == "a03111" ]]; then
  if (whiptail --title "Warning" --yesno "You're running a $Model,\nthis script is tested for a Raspberry Pi 4 with at least 2GB memory.\n\nIf you continue mounting the /tmp to RAM will be disabled.\n\nContinue anyway?" 12 78); then
    UNSAFE=yes
    PI4=yes
  else
    clear
    exit
  fi
elif [[ $Model != "not supported!" ]]; then
    UNSAFE=no
    PI4=yes
  else
    whiptail --title "Error" --msgbox "Installation canceled! You're running a model that is not supported!" 8 78
  clear
  exit
fi
