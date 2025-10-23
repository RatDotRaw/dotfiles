#!/bin/bash

source ./helpers.sh

# exit immediately if a command exits with a non-zero status.
set -e

echo -e "${GREEN}Arch Linux Quickstart Script${NC}"
echo -e "${YELLOW}This script will install various packages and configure your system.${NC}"
echo -e "${YELLOW}Please ensure you have an active internet connection.${NC}"
read -p "Press Enter to continue or Ctrl+C to abort."

echo -e "${YELLOW}:: Performing initial system update...${NC}"
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

echo -e "${YELLOW}:: Performing a full system update with paru...${NC}"
paru -Syu --noconfirm || { echo -e "${RED}Error performing paru system update.${NC}"; exit 1; }
echo -e "${GREEN}:: Full system updated with paru.${NC}"

echo -e "${YELLOW}:: Installing my core pacman packages...${NC}"
PACMAN_PACKAGES=(
    # Configs
    "openssh" # TODO: enable `sshd` service for ssh server
    "zsh"

    # Drivers
    "cuda" 
    "nvidia" 
    "nvidia-container-toolkit"

    # Desktop Shenanigans
    "ly" # Login manager
    "plasma-desktop"
    "gamescope"
    "niri"
    "xwayland-satellite" # for niri
    "xdg-desktop-portal-gnome" # for screencasting (niri)
    "swww" # for backgound (niri)
    "gnome-keyring"
    "libsecret" # (not) required for gnome-keyring

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
    "konsole"

    # Utilities
    "ark"
    "man"

    # Other
    "steam"
    "cmake"
    "cups"
)
install_pacman_packages "${PACMAN_PACKAGES[@]}"

echo -e "${YELLOW}:: Installing AUR packages... (using paru)${NC}"
PARU_PACKAGES=(
    # Configs
    "oh-my-zsh-git"

    # VR
    "monado"
    "alvr-nvidia"
)
install_paru_packages "${PARU_PACKAGES}"

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
    "io.github.flattool.Warehouse"
    "com.github.tchx84.Flatseal"
)
install_flatpak_apps "${FLATPAK_APPS[@]}"

# --- enable services ---
# login manager (ly)
log_info "Enabling ly.service (login manager)"
sudo systemctl enable ly.service || log_error "Error starting ly.service"
login_success "ly.service hs been successfully activated"

# printers (cups)
log_info "Enabling Cups using socket activation"
sudo systemctl disable cups.service
sudo systemctl enable --now cups.socket
log_success "CUPS socket activation enabled!"
log_info "Enabling avahi-daemon.service"
sudo sustemctl enable --now avahi-daemon.service
log_success "avahi-daemon.service enabled!"

# --- post install Configs ---

# NVIDIA Driver Config
echo -e "${YELLOW}:: Generating NVIDIA CDI configuration...${NC}"
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml || { echo -e "${RED}Error generating NVIDIA CDI config.${NC}"; }
echo -e "${GREEN}:: NVIDIA CDI config generated.${NC}"

# Zsh Config
echo -e "${YELLOW}:: Configuring Zsh...${NC}"
echo -e "You will be prompted to enter your password to change your default shell to Zsh."
sudo chsh -s /usr/bin/zsh "$(whoami)" || { echo -e "${RED}Error changing default shell to Zsh.${NC}"; }
echo -e "${GREEN}:: Zsh configured. Log out and back in for changes to take effect.${NC}"


echo -e "${GREEN}***************************************************${NC}"
echo -e "${GREEN}* Arch Linux Quickstart Script Finished!          *${NC}"
echo -e "${GREEN}* Most software should now be installed.          *${NC}"
echo -e "${GREEN}* Remember to log out and back in for shell changes.${NC}"
echo -e "${GREEN}***************************************************${NC}"