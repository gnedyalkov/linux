#!/bin/bash

### EDIT THESE VARIABLES BASED ON YOUR NEEDS ###
server_hostname="server.hostname.here"
server_timezone="Europe/London"
server_nameserver1="9.9.9.9"
server_nameserver2="1.1.1.1"
server_swapfile_size="4G"
new_user_account_name=username_here
new_user_account_pass=pass_here

# Set hostname
hostnamectl set-hostname $server_hostname

# Set timezone
timedatectl set-timezone $server_timezone

# Disabling IPv6 on Kernel Level
# Make a copy of the grub config file first
cp /etc/default/grub /etc/default/grub.bak

# Add ipv6.disable=1 to grub's config file
sed -i 's/^GRUB_CMDLINE_LINUX="/&ipv6.disable=1 /' /etc/default/grub

# Update the grub
update-grub2

# Update our system
apt update
apt upgrade -y
apt autoremove -y

# Install some useful tools
apt install -y unattended-upgrades update-notifier-common net-tools vim wget

# Set swap file
fallocate -l $server_swapfile_size /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Make sure SWAP is loaded on boot
cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# Optimize SWAP usage
cp /etc/sysctl.conf /etc/sysctl.conf.bak
echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure = 50' | tee -a /etc/sysctl.conf
