#!/bin/bash

# To connect to wifi:
#	wifi-menu or nmtui
# To install big font:
# 	pacman -Sy terminus-font
# 	setfont ter-p32n

sgdisk -Z /dev/sda
sgdisk -z /dev/sda
sgdisk -o /dev/sda

sgdisk -n 1:0:-200M /dev/sda
sgdisk -t 1:8300 /dev/sda

sgdisk -n 2:-200M:-0 /dev/sda
sgdisk -t 2:ef00 /dev/sda
sgdisk -A 2:set:2 /dev/sda

mkfs.ext4 -F /dev/sda1
mkfs.fat -F32 /dev/sda2

mount /dev/sda1 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda2 /mnt/boot/efi

pacstrap /mnt base base-devel linux linux-firmware grub efibootmgr vim networkmanager

cp $0 /mnt/root/

genfstab -U -p /mnt > /mnt/etc/fstab

ln -sf /mnt/usr/share/zoneinfo/US/Pacific /mnt/etc/localtime

echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
sed -i "s/#en_US.UTF/en_US.UTF/" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

echo "archlinux" > /mnt/etc/hostname
arch-chroot /mnt systemctl enable NetworkManager.service

arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=grub --efi-directory=/boot/efi --recheck
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
mkdir -p /mnt/boot/efi/EFI/BOOT
cp /mnt/boot/efi/EFI/GRUB/grubx64.efi /mnt/boot/efi/EFI/BOOTX64.EFI

