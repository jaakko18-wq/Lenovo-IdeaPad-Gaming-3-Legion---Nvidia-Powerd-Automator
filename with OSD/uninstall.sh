#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit
fi

# Identify the actual user to clean up user-specific services
REAL_USER=$SUDO_USER
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "-------------------------------------------------------"
echo "Uninstalling Lenovo Nvidia Powerd Automator..."
echo "-------------------------------------------------------"

# 1. Remove system-level components
echo "[1/3] Removing system-level services and rules..."

# Stop and disable systemd units
systemctl disable --now nvidia-powerd-restart.path 2>/dev/null
systemctl disable --now nvidia-powerd-restart.service 2>/dev/null

# Delete system files
rm -f /etc/systemd/system/nvidia-powerd-restart.path
rm -f /etc/systemd/system/nvidia-powerd-restart.service
rm -f /etc/udev/rules.d/99-nvidia-power-ac.rules

# 2. Remove user-level OSD components (if installed)
if [ -f "$USER_HOME/.local/bin/nvidia-osd.sh" ] || [ -f "$USER_HOME/.config/systemd/user/nvidia-osd.service" ]; then
    echo "[2/3] Removing OSD components for user: $REAL_USER"

    # Disable user service as the actual user
    sudo -u "$REAL_USER" XDG_RUNTIME_DIR=/run/user/$(id -u "$REAL_USER") systemctl --user disable --now nvidia-osd.service 2>/dev/null

    # Remove user files
    rm -f "$USER_HOME/.local/bin/nvidia-osd.sh"
    rm -f "$USER_HOME/.config/systemd/user/nvidia-osd.service"
else
    echo "[2/3] No OSD components found to remove."
fi

# 3. Reload system configurations
echo "[3/3] Reloading system daemons..."
systemctl daemon-reload
udevadm control --reload-rules
systemctl reset-failed

echo "-------------------------------------------------------"
echo "Uninstallation Complete!"
echo "The system has been restored to its original state."
echo "-------------------------------------------------------"
