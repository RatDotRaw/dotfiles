#!/bin/bash

set -e
source "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

install_pacman_packages "pciutils"

PACMAN_GPU_PACKAGES=()

HAS_NVIDIA=false
HAS_AMD=false
HAS_INTEL=false

NVIDIA_OPEN=false

if lspci | grep -E "VGA|3D|Display" | grep -iq "NVIDIA"; then
    HAS_NVIDIA=true
fi
if lspci | grep -E "VGA|3D|Display" | grep -iqE "AMD|ATI"; then
    HAS_AMD=true
fi
if lspci | grep -E "VGA|3D|Display" | grep -iq "Intel"; then
    HAS_INTEL=true
fi

PROPRIETARY_NVIDiA_PACKAGES=(
    "nvidia-open-dkms"
    "nvidia-utils"
    "lib32-nvidia-utils"
    "cuda"
    "nvidia-container-toolkit"
)
OPEN_NVIDIA_PACKAGES=(
    "mesa"
    "lib32-mesa"
    "vulkan-nouveau"
    "lib32-vulkan-nouveau"
)

if [ "$HAS_NVIDIA" = true ]; then
    if [ "$NVIDIA_OPEN" = false ]; then
        log_info "Removing open-source drivers if installed."
        remove_pacman_packages "${OPEN_NVIDIA_PACKAGES[@]}"
        PACMAN_GPU_PACKAGES+=("${PROPRIETARY_NVIDiA_PACKAGES[@]}")
    else
        log_warning "CUDA and NVIDIA Container Toolkit are not supported with nouveau."
        log_info "Removing proprietary drivers if installed."
        remove_pacman_packages "${PROPRIETARY_NVIDiA_PACKAGES[@]}"
        PACMAN_GPU_PACKAGES+=("${OPEN_NVIDiA_PACKAGES[@]}")
    fi
fi
if [ "$HAS_AMD" = true ]; then
    PACMAN_GPU_PACKAGES+=("mesa" "lib32-mesa" "vulkan-radeon" "lib32-vulkan-radeon")
fi
if [ "$HAS_INTEL" = true ]; then
    PACMAN_GPU_PACKAGES+=("mesa" "lib32-mesa" "vulkan-intel" "lib32-vulkan-intel")
fi


if [ "${#PACMAN_GPU_PACKAGES[@]}" -gt 0 ]; then
    install_pacman_packages "${PACMAN_GPU_PACKAGES[@]}"
fi

if [ "$NVIDIA_OPEN" = false ]; then
    if ! lsmod | grep -q "^nvidia "; then
        log_warning "NVIDIA kernel module not loaded. Attempting to load it..."
        sudo modprobe nvidia || true
    fi

    if lsmod | grep -q "^nvidia "; then
        log_info "Generating NVIDIA CDI configuration..."
        sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml || { log_error "Error generating NVIDIA CDI config."; }
    else
        log_warning "NVIDIA kernel module could not be loaded. Skipping CDI config generation."
        log_warning "Please generate it after reboot with: nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml"
    fi
fi