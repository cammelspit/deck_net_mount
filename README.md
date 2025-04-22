# deck_net_mount: Automated SMB and NFS Share Mounting with systemd

**deck_net_mount** is a lightweight Bash-based utility that automatically discovers and mounts available **SMB** or **NFS** shares from a given server using systemd `.mount` units. It is particularly useful for Linux users who want a persistent setup for their remote file shares with minimal manual configuration. This was originally put toghether for my personal use on the SteamDeck but it also has been tested and works perfectlty with my Arch based main Linux system.



## Features

- 🔍 **Auto-discovers available shares** (using `smbclient` or `showmount`)
- ⚙️ **Generates systemd mount units** for persistent and reliable mounting
- 🗂 **Supports both SMB and NFS protocols**
- 🔐 Accepts credentials interactively for secure setup (SMB)
- 🛠 Creates necessary mount target directories automatically
- 🖥️ Compatible with desktop and headless/server environments

---

## Requirements

The two scripts here should work with almost any system that uses systemd as an init system. Make sure you have the correct packages installed onto your system that provide smbclient (SMB) and showmount (NFS).

On mainline Arch Linux
sudo pacman -S --needed smbclient cifs-utils nfs-utils

SteamOS already has all the packages and such installed by default.

Specifically for SteamOS, you will need a sudo password. This is not enabled by default for SteamOS. all you need to do is pop into desktop mode, open your terminal (Konsole by default), and type "passwd". It will then ask your for the password you would like. Once done, you should be fine.

---

## Installation

git clone https://github.com/cammelspit/deck_net_mount.git

cd deck_net_mount

./smb_setup.sh #For SMB shares
 or
./nfs_setup.sh #For NFS shares
