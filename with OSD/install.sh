#!/bin/bash

# Tarkistetaan pääkäyttäjäoikeudet
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit
fi

REAL_USER=$SUDO_USER
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "-------------------------------------------------------"
echo "Installing Lenovo Nvidia Powerd Automator & OSD..."
echo "-------------------------------------------------------"

# 1. Järjestelmätason palvelu (Nvidia restart)
echo "[1/4] Creating system-wide service (Nvidia)..."
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

# 2. Järjestelmätason polkuvahti (Fn+Q)
echo "[2/4] Creating system-wide path monitor..."
cat <<EOF > /etc/systemd/system/nvidia-powerd-restart.path
[Unit]
Description=Watch for Lenovo Platform Profile changes

[Path]
PathModified=/sys/firmware/acpi/platform_profile

[Install]
WantedBy=multi-user.target
EOF

# 3. Udev-sääntö (Laturi)
echo "[3/4] Creating udev rule for AC adapter..."
cat <<EOF > /etc/udev/rules.d/99-nvidia-power-ac.rules
SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/bin/systemd-run --no-block /usr/bin/bash -c 'sleep 5; /usr/bin/systemctl restart nvidia-powerd.service'"
EOF

# 4. VALINNAINEN: KDE OSD -ilmoitukset
echo "-------------------------------------------------------"
read -p "Do you want to install KDE Plasma 6 OSD notifications? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "[*] Setting up KDE OSD for user $REAL_USER..."

    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.local/bin"
    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/systemd/user"

    cat <<EOF > "$USER_HOME/.local/bin/nvidia-osd.sh"
#!/bin/bash
sleep 5
gdbus monitor --system --dest net.hadess.PowerProfiles --object-path /net/hadess/PowerProfiles | \\
while read -r line; do
    if [[ "\$line" == *"ActiveProfile"* ]]; then
        PROFILE=\$(powerprofilesctl get)
        case "\$PROFILE" in
            "performance") ICON="power-profile-performance-symbolic"; TEXT="Performance Mode" ;;
            "balanced") ICON="power-profile-balanced-symbolic"; TEXT="Balanced Mode" ;;
            "quiet"|"power-saver") ICON="power-profile-power-saver-symbolic"; TEXT="Quiet Mode" ;;
            *) ICON="preferences-system-power"; TEXT="Profile: \$PROFILE" ;;
        esac
        qdbus6 org.kde.plasmashell /org/kde/osdService showText "\$ICON" "\$TEXT"
    fi
done
EOF
    chmod +x "$USER_HOME/.local/bin/nvidia-osd.sh"
    chown "$REAL_USER:$REAL_USER" "$USER_HOME/.local/bin/nvidia-osd.sh"

    cat <<EOF > "$USER_HOME/.config/systemd/user/nvidia-osd.service"
[Unit]
Description=KDE OSD Notification for Power Profiles
After=graphical-session.target

[Service]
ExecStart=$USER_HOME/.local/bin/nvidia-osd.sh
Restart=always

[Install]
WantedBy=default.target
EOF
    chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/systemd/user/nvidia-osd.service"

    echo "[*] KDE OSD files created."
fi

# Aktivointi
systemctl daemon-reload
systemctl enable --now nvidia-powerd-restart.path
udevadm control --reload-rules

echo "-------------------------------------------------------"
echo "Installation complete!"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "To activate OSD, run this command (NO sudo):"
    echo "systemctl --user enable --now nvidia-osd.service"
fi
echo "-------------------------------------------------------"
