#!/bin/bash

set -e
source "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

install_pacman_packages "cups" "avahi"

systemctl disable cups.service
systemctl enable avahi-daemon.service
systemctl enable cups.socket