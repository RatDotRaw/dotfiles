#!/bin/bash

source ./helpers.sh

# exit immediately if a command exits with a non-zero status.
set -e

echo -e "${GREEN}******************************************************************************${NC}"
echo -e "${GREEN}* Arch Linux Quickstart Script                                               *${NC}"
echo -e "${GREEN}*                                                                            *${NC}"
echo -e "${GREEN}* This script acts as a bootstrapper.                                        *${NC}"
echo -e "${GREEN}* It installs packages and performs partial system configuration.            *${NC}"
echo -e "${GREEN}*                                                                            *${NC}"
echo -e "${GREEN}* You will be asked multiple yes/no questions to choose what gets installed. *${NC}"
echo -e "${GREEN}* Stay at your keyboard and pay attention.                                   *${NC}"
echo -e "${GREEN}*                                                                            *${NC}"
echo -e "${YELLOW}* Sudo access is required.                                                   *${NC}"
echo -e "${YELLOW}* You will be prompted for your password several times during execution.     *${NC}"
echo -e "${GREEN}******************************************************************************${NC}"
read -p "Press Enter to continue or Ctrl+C to abort. After reading the above ofc."

echo -e "${YELLOW}:: Performing initial system update...${NC}"
read -p "Press Enter to continue or Ctrl+C to abort."
sudo pacman -Syu --noconfirm || { echo -e "${RED}Error updating system.${NC}"; exit 1; }
echo -e "${GREEN}:: System updated successfully.${NC}"

# --- install package managers ---
# Flatpak
if ! command_exists flatpak; then
    echo -e "${YELLOW}:: Installing Flatpak...${NC}"
    sudo pacman -S --noconfirm flatpak || { echo -e "${RED}Error installing Flatpak.${NC}"; exit 1; }
    echo -e "${GREEN}:: Flatpak installed.${NC}"
else
    echo -e "${GREEN}:: Flatpak is already installed. Skipping.${NC}"
fi

# Paru
if ! command_exists paru; then
    echo -e "${YELLOW}:: Installing paru (AUR helper)...${NC}"
    sudo pacman -S --noconfirm --needed git base-devel || { echo -e "${RED}Error installing git and base-devel for paru.${NC}"; exit 1; }
    git clone https://aur.archlinux.org/paru.git
    (cd paru && makepkg -si --noconfirm) || { echo -e "${RED}Error building and installing paru.${NC}"; exit 1; }

else
    echo -e "${GREEN}:: paru is already installed. Skipping.${NC}"
fi

# echo -e "${YELLOW}:: Performing a full system update with paru...${NC}"
# paru -Syu --noconfirm || { echo -e "${RED}Error performing paru system update.${NC}"; exit 1; }
# echo -e "${GREEN}:: Full system updated with paru.${NC}"

if confirm "Go through GPU-related setup?"; then
    PACMAN_GPU_PACKAGES=()
    GPU_32BIT=false
    AMD_GPU=false
    INTEL_GPU=false
    NVIDIA_GPU=false
    NVIDIA_MODERN=false
    NVIDIA_OPEN=false
    CONFIG_NVIDIA_TOOLKIT=false

    # Ask high-level questions
    if confirm "Do you have an AMD GPU?"; then
        AMD_GPU=true
    fi
    if confirm "Do you have an Intel GPU?"; then
        INTEL_GPU=true
    fi
    if confirm "Do you have an NVIDIA GPU?"; then
        NVIDIA_GPU=true
        if confirm "Is it a modern NVIDIA GPU (Turing / GTX 16xx, RTX 20xx or newer, ~2018+)?"; then
            NVIDIA_MODERN=true
            if confirm "Use open-source kernel module (nvidia-open-dkms) instead of proprietary (nvidia-dkms)? (Recommended: yes for modern GPUs - kernel is open, firmware still proprietary)"; then
                NVIDIA_OPEN=true
            fi
        else
            log_info "Legacy NVIDIA GPU detected - will use open-source nouveau driver (mesa)."
        fi
    fi

    if confirm "Install support for 32-bit applications? (recommended for gaming / Wine / Steam)"; then
        GPU_32BIT=true
    fi

    # Decide which packages to install
    if [ "$AMD_GPU" = true ] || [ "$INTEL_GPU" = true ]; then
        PACMAN_GPU_PACKAGES+=("mesa")
        if [ "$GPU_32BIT" = true ]; then
            PACMAN_GPU_PACKAGES+=("lib32-mesa")
        fi
        # Vulkan support
        if [ "$AMD_GPU" = true ]; then
            PACMAN_GPU_PACKAGES+=("vulkan-radeon")
            if [ "$GPU_32BIT" = true ]; then
                PACMAN_GPU_PACKAGES+=("lib32-vulkan-radeon")
            fi
        fi
        if [ "$INTEL_GPU" = true ]; then
            PACMAN_GPU_PACKAGES+=("vulkan-intel")
            if [ "$GPU_32BIT" = true ]; then
                PACMAN_GPU_PACKAGES+=("lib32-vulkan-intel")
            fi
        fi
    fi

    if [ "$NVIDIA_GPU" = true ]; then
        if [ "$NVIDIA_MODERN" = true ]; then
            PACMAN_GPU_PACKAGES+=("nvidia-open-dkms" "nvidia-utils")
            log_info "Selected nvidia-open-dkms (open kernel module) + nvidia-utils."
            if [ "$GPU_32BIT" = true ]; then
                PACMAN_GPU_PACKAGES+=("lib32-nvidia-utils")
            fi
            if confirm "Install CUDA? (for compute/ML, only for modern NVIDIA)"; then
                PACMAN_GPU_PACKAGES+=("cuda")
            fi
            if confirm "Install & configure NVIDIA Container Toolkit?"; then
                PACMAN_GPU_PACKAGES+=("nvidia-container-toolkit")
                CONFIG_NVIDIA_TOOLKIT=true
            fi
        else
            # Legacy - always open (nouveau) per user preference
            PACMAN_GPU_PACKAGES+=("mesa" "xf86-video-nouveau" "vulkan-nouveau")
            if [ "$GPU_32BIT" = true ]; then
                PACMAN_GPU_PACKAGES+=("lib32-mesa" "lib32-vulkan-nouveau")
            fi
            log_info "Using open-source nouveau driver for legacy NVIDIA (no proprietary packages)."
            log_warning "CUDA and NVIDIA Container Toolkit are not supported with nouveau."
        fi
    fi

    if [ "${#PACMAN_GPU_PACKAGES[@]}" -gt 0 ]; then
        install_pacman_packages "${PACMAN_GPU_PACKAGES[@]}"
    fi

    if [ "$CONFIG_NVIDIA_TOOLKIT" = true ]; then
        sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml || { log_error "Error generating NVIDIA CDI config."; }
    fi
fi

if confirm "Do you want a something like a desktop environment?"; then
    PACMAN_DE_PACKAGES=()
    PARU_DE_PACKAGES=()

    CUSTOM_THEME=false
    
    if confirm "Install the SDDM greeter for graphical login?"; then
        install_pacman_packages "sddm"
        sudo systemctl enable sddm.service || log_error "Error starting sddm.service"
        confirm "Install & configure the SilentSDDM theme?"; then
            CUSTOM_THEME=true
            PACMAN_DE_PACKAGES+=("sddm-silent-theme-git")
        fi
    fi

    if confirm "Install Niri and its dependancies?"; then
        PACMAN_DE_PACKAGES+=(
            "niri"                     # compositor
            "xwayland-satellite"       # to run x11 apps (niri)
            "xdg-desktop-portal-gnome" # for screencasting (niri)
            "awww"                     # for backgound (niri)
            "noctalia"                 # shell (niri)
            "fuzzel" 
        )
    fi

    if [ "${#PACMAN_DE_PACKAGES[@]}" -gt 0 ]; then
        install_pacman_packages "${PACMAN_DE_PACKAGES[@]}"
    fi
    if [ "${#PARU_DE_PACKAGES[@]}" -gt 0 ]; then
        install_pacman_packages "${PARU_DE_PACKAGES[@]}"
    fi

    if [ "$PARU_DE_PACKAGES" = true ]; then
        sudo git config --file=/usr/lib/sddm/sddm.conf.d/default.conf General.InputMethod qtvirtualkeyboard
        sudo git config --file=/usr/lib/sddm/sddm.conf.d/default.conf General.GreeterEnvironment "GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard"
        sudo git config --file=/usr/lib/sddm/sddm.conf.d/default.conf Theme.Current silent
    fi
fi


echo -e "${YELLOW}:: Installing my core pacman packages...${NC}"
PACMAN_PACKAGES=(
    # Configs
    "openssh" # TODO: enable `sshd` service for ssh server
    "zsh"

    # Desktop Shenanigans
    "plasma-meta"
    "gnome-keyring"
    "libsecret"               # (not) required for gnome-keyring

    # Fonts
    "noto-fonts-cjk"          # mainly asian characters
    "noto-fonts-emoji"        # for all emoji's
    "ttf-liberation"          # metric compatible font
    "ttf-jetbrains-mono-nerd"
    "ttf-nerd-fonts-symbols"  # backup for previous nerd font
    "ttf-dejavu"              # most common fallback, mathematical and technical symbols

    # Development
    "distrobox"
    "podman" 
    "podman-compose" 
    "podman-desktop"

    # Internet
    "firefox"
    "kdeconnect"

    # System
    "btop"
    "gparted"
    "alacritty"

    # Utilities
    "ark"
    "man"
    "yt-dlp"

    # Other
    "cmake"
)
install_pacman_packages "${PACMAN_PACKAGES[@]}"

echo -e "${YELLOW}:: Installing AUR packages... (using paru)${NC}"
PARU_PACKAGES=(
    # Configs
    "oh-my-zsh-git"
    "bibata-cursor-theme-bin"
)
install_paru_packages "${PARU_PACKAGES[@]}"

FLATPAK_APPS=(
    # Multimedia
    "com.spotify.Client"

    # Internet
    "dev.vencord.Vesktop"
    "im.riot.Riot" # element matrix

    # Office
    "com.logseq.Logseq"
    "org.onlyoffice.desktopeditors"

    # Utils
    "com.usebottles.bottles"
    "org.cryptomator.Cryptomator"
    "io.github.flattool.Warehouse"
    "com.github.tchx84.Flatseal"
)
install_flatpak_apps "${FLATPAK_APPS[@]}"




log_warning "Piper-tts needs manual configuration! Read 'https://wiki.archlinux.org/title/Speech_dispatcher' for instructions, I believe in you!"
if confirm "Install screen reader and TTS (piper)?"; then
    PARU_PACKAGES=("piper-tts-bin")

    if confirm "Install common voices for piper-tts? (large install size)"; then
        PARU_PACKAGES+=("piper-voices-common")
    fi

    install_pacman_packages "speech-dispatcher" "orca"
    if [ "${#PARU_PACKAGES[@]}" -gt 0 ]; then
        install_paru_packages "${PARU_PACKAGES[@]}"
    fi
fi

if confirm "Go through digital media tools and creative suite related setup (FOSS-only)?"; then
    ARCH_PACKAGES=()
    FLATPAK_PACKAGES=()
    PARU_PACKAGES=()

    if confirm "install Parabolic (youtube-dlp frontend)?"; then
        FLATPAK_PACKAGES+=("org.nickvision.tubeconverter")
    fi

    if confirm "Install video editing tools"
        # TODO: add friction when 1.0 is out.
        FLATPAK_APPS+=("org.kde.kdenlive")
    fi

    if confirm "Install Blender?"; then
        FLATPAK_PACKAGES+=("org.blender.Blender")
    fi

    if confirm "Install GIMP, Krita & Inkscape?"; then
        FLATPAK_PACKAGES+=("org.gimp.GIMP" "org.kde.krita" "org.inkscape.Inkscape")
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
fi

if confirm "Go through gaming-related setup? (Steam, Bottles, VR, etc.)"; then
    ARCH_PACKAGES=()
    FLATPAK_PACKAGES=()
    PARU_PACKAGES=()

    if confirm "Install general gaming tools? (Steam, Bottles, gamescope, Lutris)"; then
        ARCH_PACKAGES+=("steam" "gamescope" "lutris")
        FLATPAK_PACKAGES+=("bottles")
    fi
    if confirm "Set up basic VR support?"; then
        if confirm "Install Monado OpenXR runtime?"; then
            PARU_PACKAGES+=("monado")
        fi
        if confirm "Install ALVR for wireless VR?"; then
            PARU_PACKAGES+=("alvr-launcher-bin")
        fi
    fi

    if confirm "Configure pipewire for lower audio latency? This increases cpu usage and crackling audio."; then
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

    # if confirm "Install the linux-zen kernel for reduced latency, improved responsiveness and smoother multitaksing? This increases power consumption."; then
    #     ARCH_PACKAGES+=("linux-zen" "linux-zen-headers")
    # fi

    if [ "${#ARCH_PACKAGES[@]}" -gt 0 ]; then
        install_pacman_packages "${ARCH_PACKAGES[@]}"
    fi
    if [ "${#FLATPAK_PACKAGES[@]}" -gt 0 ]; then
        install_flatpak_apps "${FLATPAK_PACKAGES[@]}"
    fi
    if [ "${#PARU_PACKAGES[@]}" -gt 0 ]; then
        install_paru_packages "${PARU_PACKAGES[@]}"
    fi
fi

if confirm "Install & setup CUPS (for printers)?"; then
    install_pacman_packages "cups"
    if confirm "Use socet activation instead of service?"; then
        sudo systemctl disable cups.service
        sudo systemctl enable --now cups.socket
        log_success "CUPS socket activation enabled!"
    fi

    if confirm "Install & setup avahi-daemon (for printer discovery)?"; then
        install_pacman_packages "avahi"
        log_info "Enabling avahi-daemon.service"
        sudo sustemctl enable --now avahi-daemon.service
        log_success "avahi-daemon.service enabled!"
    fi
fi

# --- post install Configs ---

# NVIDIA Driver Config
log_info -e "$:: Generating NVIDIA CDI configuration..."
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml || { echo -e "${RED}Error generating NVIDIA CDI config.${NC}"; }
log_success ":: NVIDIA CDI config generated."

# Zsh Config
echo -e "${YELLOW}:: Configuring Zsh...${NC}"
echo -e "You will be prompted to enter your password to change your default shell to Zsh."
sudo chsh -s /usr/bin/zsh "$(whoami)" || { echo -e "${RED}Error changing default shell to Zsh.${NC}"; }
echo -e "${GREEN}:: Zsh configured. Log out and back in for changes to take effect.${NC}"


log_success "${GREEN}******************************************************${NC}"
log_success "${GREEN}* Arch Linux Quickstart Script Finished!             *${NC}"
log_success "${GREEN}* Most software should now be installed.             *${NC}"
log_success "${GREEN}* Remember to log out and back in for shell changes. *${NC}"
log_success "${YELLOW}* A system reboot coulnd't hurt at this point either *${NC}"
log_success "${GREEN}******************************************************${NC}"