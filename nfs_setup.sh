#!/usr/bin/env bash

set -euo pipefail

read -rp "Enter NFS server IP: " server_ip
read -rp "Enter base export path (e.g., /mnt/user): " base_path

# Where to store generated mount units (system-level)
unit_dir="/etc/systemd/system"
sudo mkdir -p "$unit_dir"

# Determine actual home directory of the current user
user_name="$(whoami)"
user_home="$(eval echo ~"$user_name")"
mnt_base="$user_home/mount/nfs_volumes"

# Create mount target base directory
sudo mkdir -p "$mnt_base"

# Fetch exported shares
exports=$(showmount -e "$server_ip" | awk '{print $1}' | grep "^$base_path/" || true)

if [[ -z "$exports" ]]; then
  echo "No matching exports found under $base_path from $server_ip"
  exit 1
fi

# Loop over each export and generate a mount unit
while IFS= read -r export; do
  share_name="${export##*/}"  # Get "Downloads" from "/mnt/user/Downloads"
  local_path="$mnt_base/$share_name"

  # Encode the mount unit name
  unit_name="home-${user_name}-mount-nfs_volumes-${share_name}.mount"
  unit_path="$unit_dir/$unit_name"

  echo "Creating unit: $unit_name"

  # Write the systemd mount unit
  sudo tee "$unit_path" > /dev/null <<EOF
[Unit]
Description=Mount NFS Share $share_name
Wants=network-online.target
After=network-online.target

[Mount]
What=${server_ip}:${export}
Where=${local_path}
Type=nfs
Options=rw,hard,intr,noatime,_netdev,exec
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOF

  # Create the local mount target
  sudo mkdir -p "$local_path"

  # Reload systemd and enable the mount unit
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl enable --now "$unit_name"

done <<< "$exports"

echo "All applicable NFS shares mounted and enabled."
