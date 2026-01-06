#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit
fi

echo "Installing Nvidia Powerd Automator for Lenovo..."

# 1. Create the Service file
cat <<EOF > /etc/systemd/system/nvidia-powerd-restart.service
[Unit]
Description=Restart NVIDIA Powerd after profile change
After=network.target

[Service]
Type=oneshot
ExecStartPre=/usr/bin/sleep 2
ExecStart=/usr/bin/systemctl restart nvidia-powerd.service

[Install]
WantedBy=multi-user.target
EOF

# 2. Create the Path file
cat <<EOF > /etc/systemd/system/nvidia-powerd-restart.path
[Unit]
Description=Watch for Lenovo Platform Profile changes

[Path]
PathModified=/sys/firmware/acpi/platform_profile

[Install]
WantedBy=multi-user.target
EOF

# 3. Reload and Enable
systemctl daemon-reload
systemctl enable --now nvidia-powerd-restart.path

echo "Done! The system will now automatically fix the power limit when you press Fn+Q."
