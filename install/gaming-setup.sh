#!/bin/bash

set -e
source "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

ARCH_PACKAGES=("steam" "gamescope" "gamemode" "mangohud" "lutris")
FLATPAK_PACKAGES+=("com.usebottles.bottles")

if confirm "Set up basic VR support?"; then
    if confirm "Install Monado OpenXR runtime?"; then
        PARU_PACKAGES+=("monado")
    fi
    if confirm "Install ALVR for wireless VR?"; then
        PARU_PACKAGES+=("alvr-launcher-bin")
    fi
fi


if confirm "Install common game emulators? (RetroArch, Dolphin)"; then
    ARCH_PACKAGES=("retroarch" "dolphin-emu" "ppsspp" "mame")
fi

if confirm "Configure pipewire for lower audio latency? Increases cpu usage and may cause crackling audio."; then
    # pw-top
    cat <<EOF | sudo tee /etc/pipewire/pipewire.conf.d/99-lowlatency.conf > /dev/null
context.properties = {
    default.clock.rate          = 48000
    default.clock.allowed-rates = [ 44100 48000 88200 96000 ]
    default.clock.quantum       = 64
    default.clock.min-quantum   = 32
    default.clock.max-quantum   = 1024
}
EOF || log_error "Failed to write PipeWire latency config"
fi

if [ "${#ARCH_PACKAGES[@]}" -gt 0 ]; then
    install_pacman_packages "${ARCH_PACKAGES[@]}"
fi
if [ "${#FLATPAK_PACKAGES[@]}" -gt 0 ]; then
    install_flatpak_apps "${FLATPAK_PACKAGES[@]}"
fi
if [ "${#PARU_PACKAGES[@]}" -gt 0 ]; then
    install_paru_packages "${PARU_PACKAGES[@]}"
fi

