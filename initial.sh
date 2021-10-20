#!/bin/bash

# Disabling IPv6 on Kernel Level
# Make a copy of the grub config file first
cp /etc/default/grub /etc/default/grub.bak

# Add ipv6.disable=1 to grub's config file
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/&ipv6.disable=1 /' /etc/default/grub

# Update the grub
update-grub2

# Update our system
apt update
apt upgrade -y
apt autoremove -y
