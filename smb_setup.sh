#!/usr/bin/env bash

set -euo pipefail

read -rp "Enter SMB server IP: " server_ip
read -rp "Enter base mount path (e.g., /mnt/smb): " base_path
read -rp "Enter SMB username: " smb_username
read -srp "Enter SMB password: " smb_password
echo

mnt_base="$HOME/mount/smb_volumes"
unit_dir="/etc/systemd/system"

# Ensure target base directory exists
sudo mkdir -p "$mnt_base"
sudo mkdir -p "$unit_dir"

# Get share list using smbclient
shares=$(smbclient -L "//$server_ip" -U "$smb_username%$smb_password" 2>/dev/null |
    awk '/^[ \t]*[A-Za-z0-9$_.-]+[ \t]+Disk[ \t]+/ { print $1 }')

if [[ -z "$shares" ]]; then
  echo "No valid shares found on the SMB server $server_ip"
  exit 1
fi

# Loop over shares
while IFS= read -r share; do
    share_clean=$(echo "$share" | tr -d '\r' | xargs)

    # Skip empty or invalid names
    if [[ -z "$share_clean" ]] || [[ "$share_clean" =~ [^a-zA-Z0-9._-] ]]; then
        echo "Skipping invalid share: '$share_clean'"
        continue
    fi

    local_path="$mnt_base/$share_clean"
    unit_name="home-$(whoami)-mount-smb_volumes-${share_clean}.mount"
    unit_path="$unit_dir/$unit_name"

    echo "Creating unit: $unit_name"

    sudo tee "$unit_path" > /dev/null <<EOF
[Unit]
Description=Mount SMB Share $share_clean
Wants=network-online.target
After=network-online.target

[Mount]
What=//$server_ip/$share_clean
Where=$local_path
Type=cifs
Options=rw,username=$smb_username,password=$smb_password,vers=3.0,uid=$(id -u),gid=$(id -g),nofail,x-systemd.automount,x-systemd.device-timeout=10
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOF

    sudo mkdir -p "$local_path"
    sudo systemctl daemon-reload
    sudo systemctl enable --now "$unit_name"
done <<< "$shares"

echo "All applicable SMB shares mounted and enabled."
