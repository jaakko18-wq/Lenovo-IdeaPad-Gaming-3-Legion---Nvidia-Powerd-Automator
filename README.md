# Lenovo-IdeaPad-Gaming-3-Legion---Nvidia-Powerd-Automator
This project automates the nvidia-powerd.service restart on Arch Linux when switching power profiles (e.g., via Fn+Q) or when connecting a charger. It features clean KDE Plasma 6 OSD notifications.

⚠️ Disclaimer

Use at your own risk. This software is provided "as is", without warranty of any kind. The author is not responsible for any damage to your hardware, data loss, or system instability caused by these scripts. Always review the code before running it on your system.
🌟 Features

-Fn+Q Support: Detects hardware-level profile switches and optimizes the Nvidia service immediately.

-Charger Detection: Automatically restarts the service when AC power is connected.

-KDE Plasma 6 OSD: Visual confirmation on screen using native icons (Quiet, Balanced, Performance).

-Full Automation: Runs in the background without password prompts.

🛠 Requirements

1. Kernel Driver: Lenovolegionlinux

   Enables Fn+Q and profile management on Linux.

   Arch Linux install: yay -S lenovo-legion-module-dkms-git

    Desktop Environment: KDE Plasma 6.

    Background Services: power-profiles-daemon (standard in KDE).

    Tools: qt6-declarative (provides the qdbus6 command).

🚀 Installation
1. Configure Sudoers (Passwordless Restart)

Allow the script to restart the service without a password prompt.

Open the configuration file with nano:
    Bash

    sudo EDITOR=nano visudo -f /etc/sudoers.d/nvidia-restart

Add the following line (replace yourusername with your actual username):
Plaintext

    yourusername ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nvidia-powerd.service

Save: Ctrl+O, Enter, Exit: Ctrl+X.

2. Create the Monitoring Script

This script listens to the D-Bus for profile changes.
    Bash

    mkdir -p ~/.local/bin
    nano ~/.local/bin/nvidia-profile-monitor.sh

Paste the following:
#!/bin/bash

# Listen for power profile changes
gdbus monitor --system --dest net.hadess.PowerProfiles --object-path /net/hadess/PowerProfiles | \
while read -r line; do
    if [[ "$line" == *"ActiveProfile"* ]]; then
        # Get the new profile
        PROFILE=$(powerprofilesctl get)
        
        # Match icons and text to Lenovo style
        case "$PROFILE" in
            "performance")
                ICON="power-profile-performance-symbolic"
                TEXT="Performance Mode"
                ;;
            "balanced")
                ICON="power-profile-balanced-symbolic"
                TEXT="Balanced Mode"
                ;;
            "quiet"|"power-saver")
                ICON="power-profile-power-saver-symbolic"
                TEXT="Quiet Mode"
                ;;
            *)
                ICON="preferences-system-power"
                TEXT="Profile: $PROFILE"
                ;;
        esac

        # Show KDE OSD
        qdbus6 org.kde.plasmashell /org/kde/osdService showText "$ICON" "$TEXT"

        # Delay and restart
        sleep 1.5
        sudo /usr/bin/systemctl restart nvidia-powerd.service
    fi
done

    

Apply permissions:

    chmod +x ~/.local/bin/nvidia-profile-monitor.sh

3. Setup Auto-start (Systemd)

Create a user service to start the script upon login.
Bash

    mkdir -p ~/.config/systemd/user/
    nano ~/.config/systemd/user/nvidia-profile-monitor.service

Paste the following:
    Ini, TOML

    [Unit]
    Description=Nvidia Powerd Restart on Profile Change
    After=graphical-session.target

    [Service]
    ExecStart=%h/.local/bin/nvidia-profile-monitor.sh
    Restart=always

    [Install]
    WantedBy=default.target

Enable and start:
    
    systemctl --user enable --now nvidia-profile-monitor.service

4. AC Adapter (Udev) Automation

Create a udev rule to handle charger connection:

    sudo nano /etc/udev/rules.d/99-nvidia-power-ac.rules

Paste the following:

    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/bin/systemd-run --no-block /usr/bin/bash -c 'sleep 5; /usr/bin/systemctl restart nvidia-powerd.service'"

Reload rules:

    sudo udevadm control --reload-rules

🔍 Testing

1. Press Fn+Q: An OSD should appear in the center of the screen.

2. Plug in your charger: The service will restart in the background after a 5s delay.

3. Check status:    systemctl --user status nvidia-profile-monitor.service
