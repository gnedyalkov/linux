#!/bin/bash

# Check if you are root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root. Non-root users cannot execute this script."
  exit
fi

# SET SOME VARIABLES
OS_NAME=$(egrep '^(NAME)=' /etc/os-release |awk -F '"' '{print $2}'|awk -F ' ' '{print $1}')
OS_VERSION=$(egrep '^(VERSION)=' /etc/os-release |awk -F '"' '{print $2}'|awk -F ' ' '{print $1}'|awk -F '.' '{print $1}')
TOTAL_PHSYSICAL_RAM=$(dmidecode -t memory | awk '$1 == "Size:" && $2 ~ /^[0-9]+$/ {print $2$3}'|numfmt --from=iec --suffix=B|awk '{total += $1}; END {print total}'|numfmt --to=iec --suffix=B --format=%0f|awk -F '.' '{print $1}')
FREE_DISK_SPACE=$(df -h|grep "/$"|awk -F ' ' '{print $4}')

echo "Here is some useful information about your system:"
echo ""
echo "OS = $OS_NAME"
echo "OS Version = $OS_VERSION"
echo "RAM Memory = $TOTAL_PHSYSICAL_RAM GB"
echo "Free Disk Space = $FREE_DISK_SPACE"
echo ""
echo "Let's proceed setuping your server."
echo ""

# Create new sudo user
echo "Creating new user with sudo privileges..."
echo ""
read -p "Choose name for the new user account: " NEW_USER_SUDO
#read -p "Choose password for the new user: " NEW_USER_SUDO_PASS
egrep "^$NEW_USER_SUDO" /etc/passwd > /dev/null 2>&1
if [ $? -eq 0 ]
then
  echo ""
  echo "$NEW_USER_SUDO already exists!"
  exit 1
elif [ "$OS_NAME" = "Ubuntu"  -o  "$OS_NAME" = "Debian" ]
then
  echo ""
  useradd -m -s /bin/bash "$NEW_USER_SUDO"
  passwd $NEW_USER_SUDO
  SUDO_GROUP=sudo
  usermod -aG $SUDO_GROUP $NEW_USER_SUDO
  echo "User $NEW_USER_SUDO has been created with the provided password."
 elif [ "$OS_NAME" = "CentOS"  -o  "$OS_NAME" = "Rocky" ]
 then
   echo ""
   useradd -m -s /bin/bash "$NEW_USER_SUDO"
   #echo "$NEW_USER_SUDO_PASS" | passwd --stdin "$NEW_USER_SUDO"
   passwd $NEW_USER_SUDO
   SUDO_GROUP=wheel
   usermod -aG $SUDO_GROUP $NEW_USER_SUDO
   echo "User $NEW_USER_SUDO has been created with the provided password."
fi

# Set server's timezone
read -p "Choose your Time Zone (e.g. Europe/London): " SERVER_TIMEZONE
case "$SERVER_TIMEZONE" in
  [a-zA-Z]*/*[a-zA-Z])
    timedatectl set-timezone $SERVER_TIMEZONE
    echo ""
    ;;
*)
  echo "ERROR. You should use the proper format as for example Europe/London ."
  echo ""
  ;;
esac

# Set server's hostname
read -p "Choose your hostname using the following format - server.hostname.com: " SERVER_HOSTNAME
case "$SERVER_HOSTNAME" in
  [a-z]*.*[a-z]*.*[a-z])
  cp /etc/hosts /etc/hosts.bak
  hostnamectl set-hostname $SERVER_HOSTNAME
  echo ""
  cat /dev/null > /etc/hosts
  echo "127.0.0.1 localhost" | tee -a /etc/hosts
  echo "127.0.0.1 $SERVER_HOSTNAME" | tee -a /etc/hosts
  echo ""
  ;;
*)
  echo "ERROR."
  echo ""
  ;;
esac

# Update the system
echo "Updating your $OS_NAME $OS_VERSION server..."
echo ""
if [ "$OS_NAME" = "Ubuntu"  -o  "$OS_NAME" = "Debian" ]
then
  # echo "Your system is $OS_NAME. Your package manager is APT."
  apt update
  apt upgrade -y
  apt install wget vim net-tools dmidecode -y
  apt autoremove -y
  echo ""
  echo "Update completed."
  echo ""
elif [ "$OS_NAME" = "CentOS"  -o  "$OS_NAME" = "Rocky" ] && [ "$OS_VERSION" == "8" ]
then
  # echo "Your system is $OS_NAME. Your package manager is DNF."
  dnf update -yq
  dnf install wget vim net-tools dmidecode -yq
  dnf autoremove -yq
  echo ""
  echo "Update completed."
  echo ""
elif [ "$OS_NAME" = "CentOS" ] && [ "$OS_VERSION" == "7" ]
then
  # echo "Your system is $OS_NAME. Your package manager is YUM."
  yum update -yq
  yum install -yq wget vim net-tools dmidecode
  yum autoremove -yq
  echo ""
  echo "Update completed."
  echo ""
else
  echo "Your $OS_NAME is too old (version - $OS_VERSION) and it is not supported by this script."
  echo ""
fi

# Handle the SWAP creation with proper size
echo "Setting up SWAP..."
echo ""
if [ "$TOTAL_PHSYSICAL_RAM" -lt 2 ]
then
  SWAP_SIZE=$((${TOTAL_PHSYSICAL_RAM}*2))
  echo "Your RAM is $TOTAL_PHSYSICAL_RAM GB. Your SWAP should be $SWAP_SIZE GB."
  echo ""
  SWAP_SIZE_MB=$((${SWAP_SIZE}*1024))
  dd if=/dev/zero of=/swapfile bs=1M count=$SWAP_SIZE_MB
  echo ""
elif [ "$TOTAL_PHSYSICAL_RAM" -ge 2 ]
then
  SWAP_SIZE=$((${TOTAL_PHSYSICAL_RAM}+2))
  echo "Your RAM is $TOTAL_PHSYSICAL_RAM GB. Your SWAP should be = RAM + 2GB = $SWAP_SIZE GB."
  echo ""
  SWAP_SIZE_MB=$((${SWAP_SIZE}*1024))
  dd if=/dev/zero of=/swapfile bs=1M count=$SWAP_SIZE_MB > /dev/null 2>&1
  echo ""
fi

# Correct permissions and add make the swap
if [ $(swapon -s |wc -l) != 0 ]
then
  echo "You already have SWAP file in use. Nothing to do."
else
  echo "Correcting SWAP file permissions..."
  chmod 600 /swapfile
  echo "Done."
  echo "Making the SWAP..."
  mkswap /swapfile > /dev/null 2>&1
  echo "Done."
  echo "Activating the SWAP..."
  swapon /swapfile
  echo "Done."
fi

# Make sure SWAP is loaded on boot
echo ""
echo "Making sure your SWAP loads on boot..."
echo ""
if grep -q "swap" /etc/fstab; then
  echo "SWAP is already configured in /etc/fstab"
  echo ""
else
  cp /etc/fstab /etc/fstab.bak
  echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
  echo ""
  echo "Done."
fi

# Optimize SWAP usage
echo "Optimize SWAP usage..."
cp /etc/sysctl.conf /etc/sysctl.conf.bak
echo "# Optimize SWAP usage" | tee -a /etc/sysctl.conf
echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure = 50' | tee -a /etc/sysctl.conf
echo ""
echo "Done."
