#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' 

HOSTNAME='shizai'

# Disks and Slices
IN_DEVICE=/dev/sda

if $(use_lvm) ; then
    PV_DEVICE="$ROOT_DEVICE"
    VOL_GROUP="arch_vg"
    LV_ROOT="ArchRoot"
    LV_HOME="ArchHome"
    LV_SWAP="ArchSwap"
fi

# System and packages
BASE_SYSTEM=( base base-devel linux-lts linux-lts-headers linux-firmware dkms vim nano nvim iwd git nodejs npm npm-check-updates )


echo -e "${RED}
##################################
###   BASE ARCH INSTALLATION   ###
##################################
${NC}"

# Check Boot Mode
if [[ -f /sys/firmware/efi/fw_platform_size ]]; then
    boot=$(cat /sys/firmware/efi/fw_platform_size)
    if [[ "$boot" -eq 64 ]]; then
        echo -e "${YELLOW}The system is booted in x64 UEFI Mode.${NC}"
    elif [[ "$boot" -eq 32 ]]; then
        echo -e "${YELLOW}The system is booted in IA32 UEFI Mode.${NC}"
    else
        echo "${RED}Unknown UEFI bitness.${NC}"
    fi
else
    echo "${RED}The system is booted in BIOS (or CMOS) mode.${NC}"
fi

# Test internet connection
clear
echo -e "${BLUE}Testing Internet connection...${NC}"
$(ping -c 3 archlinux.org &>/dev/null) || (echo "NOT CONNECTED" && exit 1)
echo "CONNECTED" && sleep 3

# Check time and date before installation
timedatectl set-ntp true
echo && echo -e "${BLUE}Date/Time service Status is...${NC}"
timedatectl status
sleep 4


# Disk Partitioning
echo -e "${BLUE}Identify your devices first:${NC}"
cfdisk





