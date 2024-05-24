#!/bin/bash

echo -e "\e[1;32m
   ██████╗ ███████╗██╗   ██╗███████╗██╗      ██████╗ ██████╗ ███████╗██████╗ 
   ██╔══██╗██╔════╝██║   ██║██╔════╝██║     ██╔═══██╗██╔══██╗██╔════╝██╔══██╗
   ██║  ██║█████╗  ██║   ██║█████╗  ██║     ██║   ██║██████╔╝█████╗  ██████╔╝
   ██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║     ██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗
   ██████╔╝███████╗ ╚████╔╝ ███████╗███████╗╚██████╔╝██║     ███████╗██║  ██║
   ╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝
    █████╗ ██████╗  ██████╗██╗  ██╗    ██╗  ██╗██╗████████╗                  
   ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██║ ██╔╝██║╚══██╔══╝                  
   ███████║██████╔╝██║     ███████║    █████╔╝ ██║   ██║                     
   ██╔══██║██╔══██╗██║     ██╔══██║    ██╔═██╗ ██║   ██║                     
   ██║  ██║██║  ██║╚██████╗██║  ██║    ██║  ██╗██║   ██║                     
   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚═╝   ╚═╝                     
\e[0m"

# Function to display a progress bar
show_progress() {
    local current=$1
    local total=$2
    local percent=$(( current * 100 / total ))
    local progress=$(( current * 50 / total ))
    local bar=$(printf "%-${progress}s" "=")
    printf "\r[%s] %d%%" "${bar// /=}" "$percent"
}

# Packages to install
packages=(lightdm lightdm-gtk-greeter bspwm sxhkd polybar picom dunst kitty zsh neofetch)

total=${#packages[@]}
current=0

# Install packages with progress display
for package in "${packages[@]}"; do
    echo "Installing $package..."
    sudo pacman -S --noconfirm $package
    current=$((current + 1))
    show_progress $current $total
done

# Enable LightDM
echo -e "\nEnabling LightDM..."
sudo systemctl enable lightdm.service

# Create configuration directories

USER_NAME="$USER"




CONFIG_DIR="/home/$USER_NAME/.config"


mkdir -p "$CONFIG_DIR"
chmod +777  "$CONFIG_DIR"

ARCHTOOLS_DIR="/tmp/archtools"

echo "Creating configuration directories..."
mkdir -p "$CONFIG_DIR/bspwm"
mkdir -p "$CONFIG_DIR/sxhkd"
mkdir -p "$CONFIG_DIR/polybar"
mkdir -p "$CONFIG_DIR/picom"
mkdir -p "$CONFIG_DIR/dunst"


# Copy default configurations & custom
echo "Copying default configurations..."
cp "$ARCHTOOLS_DIR/bspwmrc" "$CONFIG_DIR/bspwm/"
cp "$ARCHTOOLS_DIR/sxhkdrc" "$CONFIG_DIR/sxhkd/"
cp /etc/xdg/picom.conf "$CONFIG_DIR/picom/"
cp /etc/polybar/config.ini "$CONFIG_DIR/polybar/"
cp /etc/dunst/dunstrc "$CONFIG_DIR/dunst/"

chsh -s $(which zsh)


# install yay for linux
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

#intall powerlevel10k
yay -S --noconfirm zsh-theme-powerlevel10k-git
echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc




# Make the bspwmrc file executable
echo "Making the bspwmrc file executable..."
chmod +x ~/.config/bspwm/bspwmrc

echo "Configuration complete. Please restart your terminal or run 'exec zsh' to apply the changes."

# Credits.
echo "Credits to: https://cheatsheetfactory.geekyhacker.com/linux/arch-lightdm"
echo "YouTube video: https://www.youtube.com/watch?v=Vu5RRz11yD8 (Developer: https://github.com/DaarcyDev)"

