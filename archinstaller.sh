#!/bin/bash

# To connect to wifi:
#	wifi-menu or nmtui
# To install big font:
# 	pacman -Sy terminus-font
# 	setfont ter-p32n
set -eo pipefail
trap quit:no_message INT

INSTALL_SCRIPT=install_arch.sh
EDITOR=vim
hostname=$(dialog --stdout --inputbox "Enter hostname" 0 0) || exit 1
username=$(dialog --stdout --inputbox "Enter username" 0 0) || exit 1
password=$(dialog --stdout --passwordbox "Enter password" 0 0) || exit 1
password2=$(dialog --stdout --passwordbox "Confirm password" 0 0) || exit 1
[[ "$password" == "$password2" ]] || ( echo "Passwords did not match"; exit 1; )

devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)
device=$(dialog --stdout --menu "Select installation disk" 0 0 0 ${devicelist}) || exit 1
device_root="${device}1"
device_boot="${device}2"

write_script() {
	(
		echo "#!/usr/bin/env bash"
		echo "#"
		echo "# Please review the install script below"
		echo "#"
		echo "set -euo pipefail"
		echo
		echo "sgdisk -Z $device"
		echo "sgdisk -Z $device"
		echo "sgdisk -z $device"
		echo "sgdisk -o $device"
		echo
		echo "sgdisk -n 1:0:-200M $device"
		echo "sgdisk -t 1:8300 $device"
		echo
		echo "sgdisk -n 2:-200M:-0 $device"
		echo "sgdisk -t 2:ef00 $device"
		echo "sgdisk -A 2:set:2 $device"
		echo
		echo "mkfs.ext4 -F $device_root"
		echo "mkfs.fat -F32 $device_boot"
		echo
		echo "mount $device_root /mnt"
		echo "mkdir -p /mnt/boot/efi"
		echo "mount $device_boot /mnt/boot/efi"
		echo "pacstrap /mnt base linux linux-firmware grub efibootmgr vim networkmanager"
		echo
		echo "cp $0 /mnt/root/"
		echo
		echo "genfstab -U -p /mnt > /mnt/etc/fstab"
		echo
		echo "ln -sf /mnt/usr/share/zoneinfo/US/Pacific /mnt/etc/localtime"
		echo
		echo "echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf"
		echo "sed -i 's/#en_US.UTF/en_US.UTF/' /mnt/etc/locale.gen"
		echo "arch-chroot /mnt locale-gen"
		echo
		echo "arch-chroot /mnt sh <<EOF"
		echo "	echo ${hostname} > /etc/hostname"
		echo "EOF"
		echo "arch-chroot /mnt systemctl enable NetworkManager.service"
		echo
		echo "arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=grub --efi-directory=/boot/efi --recheck"
		echo "arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg"
		echo "mkdir -p /mnt/boot/efi/EFI/BOOT"
		echo "cp /mnt/boot/efi/EFI/GRUB/grubx64.efi /mnt/boot/efi/EFI/BOOTX64.EFI"
		echo
		echo "# setup sudo"
		echo "arch-chroot /mnt sh <<EOF"
		echo "	pacman -Syu --noconfirm sudo"
		echo "	echo '%wheel ALL=(ALL) ALL' | sudo EDITOR='tee -a' visudo"
		echo "EOF"
		echo
		echo "# create user"
		echo "arch-chroot /mnt sh <<EOF"
		echo "	useradd -Nm -g users -G wheel,sys \"$username\""
		echo "	echo -e "$password"\"\\n\"$password | passwd \"$username\""
		echo "EOF"
		echo
		echo "# disallow root login"
		echo "arch-chroot /mnt passwd -l root"
	) > "$INSTALL_SCRIPT"
	chmod +x "$INSTALL_SCRIPT"
}

write_script

# open editor to review and make last changes to the script
"$EDITOR" "$INSTALL_SCRIPT"
reset

clear

dialog --title "Arch Installer" --yesno "Are you sure you want to run the script?" 7 60
response=$?
clear

case $response in
	0) bash "$INSTALL_SCRIPT";;
	1) clear && echo "Cancelling installation";;
	255) clear && echo "Cancelling installation";;
esac

