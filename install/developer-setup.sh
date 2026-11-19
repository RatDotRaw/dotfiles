#!/bin/bash

set -e
source "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

ARCH_PACKAGES=("code" "nvim" "intellij-idea-oss")
FLATPAK_PACKAGES+=("io.github.shiftey.Desktop")

if [ "${#ARCH_PACKAGES[@]}" -gt 0 ]; then
    install_pacman_packages "${ARCH_PACKAGES[@]}"
fi
if [ "${#FLATPAK_PACKAGES[@]}" -gt 0 ]; then
    install_flatpak_apps "${FLATPAK_PACKAGES[@]}"
fi