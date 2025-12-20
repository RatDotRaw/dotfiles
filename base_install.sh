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
    PACKAGES=()
    GPU_32BIT=false
    AMD_GPU=false
    INTEL_GPU=false
    NVIDIA_GPU=false
    CONFIG_NVIDIA_TOOLKIT=false

    # Ask high-level questions
    if confirm "Enable support for 32-bit applications? (recommended for old games)"; then
        GPU_32BIT=true
    fi

    if confirm "Do you have an AMD GPU?"; then
        AMD_GPU=true
    fi
    if confirm "Do you have an Intel GPU?"; then
        INTEL_GPU=true
    fi
    if confirm "Do you have a modern NVIDIA GPU?"; then
        NVIDIA_GPU=true
    fi

    # Decide which packages to install
    if [ "$AMD_GPU" = true ] || [ "$INTEL_GPU" = true ]; then
        PACKAGES+=("mesa")
        if [ "$GPU_32BIT" = true ]; then
            PACKAGES+=("lib32-mesa")
        fi
        if 
    fi

    if [ "$NVIDIA_GPU" = true ]; then
        PACKAGES+=("nvidia-dkms")
        if [ "$GPU_32BIT" = true ]; then
            PACKAGES+=("lib32-nvidia-utils")
        fi
        if confirm "Install CUDA?"; then
            PACKAGES+=("cuda")
        fi
        if confirm "Install & configure NVIDIA Container Toolkit?"; then
            PACKAGES+=("nvidia-container-toolkit")
            CONFIG_NVIDIA_TOOLKIT=true
        fi
    fi

    if [ "${#PACKAGES[@]}" -gt 0 ]; then
        install_arch_packages "${PACKAGES[@]}"
    fi

    if [ "$CONFIG_NVIDIA_TOOLKIT" = true ]; then
        sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml || { log_error "Error generating NVIDIA CDI config."; }
    fi
fi


echo -e "${YELLOW}:: Installing my core pacman packages...${NC}"
PACMAN_PACKAGES=(
    # Configs
    "openssh" # TODO: enable `sshd` service for ssh server
    "zsh"

    # Desktop Shenanigans
    "plasma-desktop"
    "gnome-keyring"
    "libsecret"                # (not) required for gnome-keyring
    
    "niri"
    "xwayland-satellite"       # to run x11 apps (niri)
    "xdg-desktop-portal-gnome" # for screencasting (niri)
    "swww"                     # for backgound (niri)
    "mako"                     # for notifications (niri)

    # Fonts
    "noto-fonts-cjk"
    "ttf-jetbrains-mono-nerd"

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


if confirm "Install the SDDM greeter?"; then
    install_pacman_packages "sddm"
    sudo systemctl enable sddm.service || log_error "Error starting sddm.service"
    confirm "Install & configure the SilentSDDM theme?"; then
        install_paru_packages "sddm-silent-theme-git"
        sudo git config --file=/usr/lib/sddm/sddm.conf.d/default.conf General.InputMethod qtvirtualkeyboard
        sudo git config --file=/usr/lib/sddm/sddm.conf.d/default.conf General.GreeterEnvironment "GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard"
        sudo git config --file=/usr/lib/sddm/sddm.conf.d/default.conf Theme.Current silent
    fi
fi

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

    if [ "${#ARCH_PACKAGES[@]}" -gt 0 ]; then
        install_paru_packages "${ARCH_PACKAGES[@]}"
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