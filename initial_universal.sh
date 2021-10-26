#!/bin/bash

# SET SOME VARIABLES
OS_NAME=$(egrep '^(NAME)=' /etc/os-release |awk -F '"' '{print $2}'|awk -F ' ' '{print $1}')
OS_VERSION=$(egrep '^(VERSION)=' /etc/os-release |awk -F '"' '{print $2}'|awk -F ' ' '{print $1}'|awk -F '.' '{print $1}')
TOTAL_PHSYSICAL_RAM=$(dmidecode -t memory | awk '$1 == "Size:" && $2 ~ /^[0-9]+$/ {print $2$3}'|numfmt --from=iec --suffix=B|awk '{total += $1}; END {print total}'|numfmt --to=iec --suffix=B --format=%0f|awk -F '.' '{print $1}')
FREE_DISK_SPACE=$(df -h|grep "/$"|awk -F ' ' '{print $4}')

echo "The OS is - $OS_NAME"
echo "The OS version is - $OS_VERSION"
echo "You have $TOTAL_PHSYSICAL_RAM GB RAM"
echo "You have $FREE_DISK_SPACE free disk space"

# Update the system
if [ "$OS_NAME" = "Ubuntu"  -o  "$OS_NAME" = "Debian" ]
then
  echo "Your system is $OS_NAME. Your package manager is APT."
  apt update
  apt upgrade -y
  apt install wget vim net-tools dmidecode -y
  apt autoremove -y
elif [ "$OS_NAME" = "CentOS"  -o  "$OS_NAME" = "Rocky" ] && [ "$OS_VERSION" == "8" ]
then
  echo "Your system is $OS_NAME. Your package manager is DNF."
  dnf update -y
  dnf install wget vim net-tools dmidecode -y
  dnf autoremove -y
elif [ "$OS_NAME" = "CentOS" ] && [ "$OS_VERSION" == "7" ]
then
  echo "Your system is $OS_NAME. Your package manager is YUM."
else
  echo "Your $OS_NAME is too old (version - $OS_VERSION) and it is not supported by this script."
fi

# # Handle the SWAP creation with proper size
# if [ "$TOTAL_PHSYSICAL_RAM" -lt 2 ]
# then
#   SWAP_SIZE=$((${TOTAL_PHSYSICAL_RAM}*2))
#   echo "Your RAM is less than 2GB. You need X2 SWAP. Your RAM is $TOTAL_PHSYSICAL_RAM GB. Your SWAP should be $SWAP_SIZE GB."
#   fallocate -l $SWAP_SIZE /swapfile
# elif [ "$TOTAL_PHSYSICAL_RAM" -ge 2 ]
# then
#   SWAP_SIZE=$((${TOTAL_PHSYSICAL_RAM}+2))
#   echo "Your RAM is greater or equal to 2GB. Your RAM is $TOTAL_PHSYSICAL_RAM GB. You need SWAP = RAM + 2GB = $SWAP_SIZE GB."
#   fallocate -l $SWAP_SIZE /swapfile
# fi
#
# ###
# ## install wget vim net-tools dmidecode
#
# # Correct permissions and add make the swap
# chmod 600 /swapfile
# mkswap /swapfile
# swapon /swapfile
#
# # Make sure SWAP is loaded on boot
# cp /etc/fstab /etc/fstab.bak
# echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
