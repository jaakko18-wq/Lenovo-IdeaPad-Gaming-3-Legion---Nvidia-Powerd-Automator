#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit
fi

echo "Uninstalling Nvidia Powerd Automator..."

systemctl disable --now nvidia-powerd-restart.path
systemctl disable --now nvidia-powerd-restart.service

rm -f /etc/systemd/system/nvidia-powerd-restart.path
rm -f /etc/systemd/system/nvidia-powerd-restart.service

systemctl daemon-reload
systemctl reset-failed

echo "Uninstalled successfully."
