#!/bin/bash

set -e
source "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

install_pacman_packages "networkmanager" "bluez" "bluez-utils" "wireless-regdb"

systemctl enable systemd-resolved.service
systemctl enable NetworkManager || { echo -e "${RED}Error enabling NetworkManager.service. You should really look into this.${NC}"; }
systemctl enable bluetooth.service