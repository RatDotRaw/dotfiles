#!/bin/bash

# --- Colors for better output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    type "$1" &> /dev/null
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Pacman Package installation helper
install_pacman_packages() {
    local packages=("$@")
    echo -e "${YELLOW}:: Installing Arch packages with pacman...${NC}"
    sudo pacman -S --noconfirm "${packages[@]}" || { echo -e "${RED}Error installing pacman packages.${NC}"; exit 1; }
    echo -e "${GREEN}:: Finished installing pacman packages.${NC}"
}

remove_pacman_packages() {
    local packages=("$@")
    local installed_packages=()
    for pkg in "${packages[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            installed_packages+=("$pkg")
        fi
    done
    if [ "${#installed_packages[@]}" -eq 0 ]; then
        echo -e "${YELLOW}:: No packages to remove, skipping.${NC}"
        return 0
    fi
    echo -e "${YELLOW}:: Removing Arch packages with pacman...${NC}"
    sudo pacman -Rsu --noconfirm "${installed_packages[@]}" || { echo -e "${RED}Error removing pacman packages.${NC}"; exit 1; }
    echo -e "${GREEN}:: Finished removing pacman packages.${NC}"
}

# Paru Package install helper
install_paru_packages() {
    local packages=("$@")
    echo -e "${YELLOW}:: Installing AUR packages with paru...${NC}"
    paru -S --noconfirm "${packages[@]}" || { echo -e "${RED}Error installing yay packages.${NC}"; exit 1; }
    echo -e "${GREEN}:: Finished installing paru packages.${NC}"
}

# Flatpak Package Install helper
install_flatpak_apps() {
    local apps=("$@")
    echo -e "${YELLOW}:: Installing Flatpak applications...${NC}"
    for app in "${apps[@]}"; do
        echo -e "${YELLOW}:: Installing Flatpak app: $app${NC}"
        flatpak install --or-update --noninteractive flathub "$app" || { echo -e "${RED}Error installing Flatpak app: $app${NC}"; }
    done
    echo -e "${GREEN}:: Finished installing Flatpak applications.${NC}"
}

# Create directory with parents
create_dir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" && log_success "Created directory: $dir"
    else
        log_info "Directory already exists: $dir"
    fi
}

# Backup file if it exists
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        mv "$file" "${file}.backup.$(date +%s)"
        log_info "Backed up $file"
    fi
}

# Confirm with user
confirm() {
    local prompt="${1:-Are you sure?}"
    read -p "$prompt [y/N]: " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "This script should not be run as root"
        exit 1
    fi
}