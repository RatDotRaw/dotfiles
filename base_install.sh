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
sudo pacman -Syu --noconfirm git crudini || { echo -e "${RED}Error updating system.${NC}"; exit 1; }
echo -e "${GREEN}:: System updated successfully.${NC}"

bash ./install/pacman-setup.sh

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
    sudo pacman -S --noconfirm --needed base-devel || { echo -e "${RED}Error installing git and base-devel for paru.${NC}"; exit 1; }
    git clone https://aur.archlinux.org/paru.git
    (cd paru && makepkg -si --noconfirm) || { echo -e "${RED}Error building and installing paru.${NC}"; exit 1; }
    # TODO: clean up after install
else
    echo -e "${GREEN}:: paru is already installed. Skipping.${NC}"
fi

if confirm "Go through GPU-related setup?"; then
    bash ./install/hardware-setup.sh
fi

if confirm "Go through gaming-related setup? (Steam, Bottles, VR, etc.)?"; then
    bash ./install/gaming-setup.sh
fi

if confirm "Install developer related packages?"; technical
    bash ./install/developer-setup.sh
fi

if confirm "Install & setup CUPS (for printers)?"; then
    bash ./install/printer-setup.sh
fi

if confirm "Do you want a something like a desktop environment?"; then
    PACMAN_DE_PACKAGES=()
    PARU_DE_PACKAGES=()

    CUSTOM_THEME=false
    
    if confirm "Install the SDDM greeter for graphical login?"; then
        install_pacman_packages "sddm"
        sudo systemctl enable sddm.service || log_error "Error starting sddm.service"
        sudo git config --file=/usr/lib/sddm/sddm.conf.d/default.conf General.Numlock on
        confirm "Install & configure the SilentSDDM theme?"; then
            CUSTOM_THEME=true
            PARU_DE_PACKAGES+=("sddm-silent-theme-git")
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
        install_paru_packages "${PARU_DE_PACKAGES[@]}"
    fi

    if [ "$CUSTOM_THEME" = true ]; then
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
    "noto-fonts-cjk"          # mainly asian & latin characters
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
        ARCH_PACKAGES+=("kdenlive")
    fi

    if confirm "Install Blender?"; then
        FLATPAK_PACKAGES+=("org.blender.Blender")
        ARCH_PACKAGES+=("blender")
    fi

    if confirm "Install GIMP, Krita & Inkscape?"; then
        ARCH_PACKAGES+=("krita", "gimp", "inkscape")
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

# --- post install Configs ---

bash ./install/network-setup.sh

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