Linux Lenovo IdeaPad Gaming 3 & Legion Nvidia Powerd Automator

This project automates the nvidia-powerd.service restart on Linux (specifically tested on Lenovo IdeaPad Gaming 3 15ACH6) when switching power profiles (via Fn+Q) or connecting a charger.
🔍 The Problem

On many Lenovo laptops, the NVIDIA GPU's Total Graphics Power (TGP) can get stuck. For example, the GPU might be capped at 60W even when it should reach 85W or higher in Performance mode.

This happens because the nvidia-powerd service fails to detect the hardware-level profile switch in real-time. Restarting the service manually fixes this and unlocks the full TDP, and this project automates that process.
⚠️ Disclaimer

Use at your own risk. The author is not responsible for any damage to your hardware, data loss, or system instability. Always review the code before running it.
🌟 Features

   Fn+Q Support: Detects hardware-level profile switches and refreshes the NVIDIA service immediately.

   Charger Detection: Automatically restarts the service when AC power is connected to ensure full power.

   Event-Driven (Systemd Path): Zero CPU usage. It only triggers when the profile file is modified.

   KDE Plasma 6 OSD: Optional visual confirmation on screen using native icons.

🛠 Requirements

   Kernel Driver: lenovolegionlinux (Enables Fn+Q and profile management).

   NVIDIA Drivers: Proprietary drivers with nvidia-powerd.service enabled.

   KDE Plasma 6 (Optional, for OSD notifications).

🚀 Installation
Option 1: Automatic Installation (Recommended)

This method installs the Version 2 (systemd path unit), which is the most lightweight and reliable way.

Clone the repository:

      git clone https://github.com/jaakko18-wq/Lenovo-IdeaPad-Gaming-3-Legion-Nvidia-Powerd-Automator.git
      cd Lenovo-IdeaPad-Gaming-3-Legion-Nvidia-Powerd-Automator

Run the installer:

    sudo chmod +x install.sh
    sudo ./install.sh

Option 2: AC Adapter (Udev) Automation

To handle charger connections separately, you can add a udev rule:

Create the rule file: 
   
      sudo nano /etc/udev/rules.d/99-nvidia-power-ac.rules

   Paste:

      SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/bin/systemd-run --no-block /usr/bin/bash -c 'sleep 5; /usr/bin/systemctl restart nvidia-powerd.service'"

Reload rules: 
         
         sudo udevadm control --reload-rules

🖥 KDE Plasma 6 Notifications (Advanced)

If you want KDE OSD notifications, you can use the monitor script included in the legacy_script folder:

   Ensure qt6-declarative (for qdbus6) is installed.

   The script listens to D-Bus for ActiveProfile changes and triggers the KDE OSD Service.

🔍 Verification

To verify the fix is working, switch profiles with Fn+Q and check the service status:

      systemctl status nvidia-powerd.service

The status should show that the service was restarted a few seconds ago. You can also monitor real-time power draw:

      nvidia-smi -q -d POWER

Uninstallation

To remove the automation and clean up system files:

      sudo chmod +x uninstall.sh
      sudo ./uninstall.sh
