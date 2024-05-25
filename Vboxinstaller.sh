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
packages=(lightdm lightdm-gtk-greeter bspwm sxhkd polybar picom dunst kitty zsh neofetch firefox)

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

# User and config directories
USER_NAME="$USER"
CONFIG_DIR="/home/$USER_NAME/.config"
ARCHTOOLS_DIR="/tmp/archtools"

# Create and set permissions for configuration directories
echo "Creating and setting permissions for configuration directories..."
mkdir -p "$CONFIG_DIR/bspwm" "$CONFIG_DIR/sxhkd" "$CONFIG_DIR/polybar" "$CONFIG_DIR/picom" "$CONFIG_DIR/dunst" "$CONFIG_DIR/polybar/script"
chmod 777 "$CONFIG_DIR" "$CONFIG_DIR/bspwm" "$CONFIG_DIR/sxhkd" "$CONFIG_DIR/polybar" "$CONFIG_DIR/picom" "$CONFIG_DIR/dunst"  "$CONFIG_DIR/polybar/script"

# Copy default configurations
echo "Copying default configurations..."
cp "$ARCHTOOLS_DIR/bspwmrc" "$CONFIG_DIR/bspwm/"
cp "$ARCHTOOLS_DIR/sxhkdrc" "$CONFIG_DIR/sxhkd/"
cp "$ARCHTOOLS_DIR/launch.sh" "$CONFIG_DIR/polybar/script/"
cp /etc/xdg/picom.conf "$CONFIG_DIR/picom/"
cp "$ARCHTOOLS_DIR/config.ini" "$CONFIG_DIR/polybar/"
cp /etc/dunst/dunstrc "$CONFIG_DIR/dunst/"

# Change shell to zsh for the current user
echo "Changing shell to zsh..."
chsh -s $(which zsh)

# Install yay for AUR packages
echo "Installing yay..."
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..

# Install powerlevel10k theme
echo "Installing powerlevel10k theme..."
yay -Sy --noconfirm ttf-meslo-nerd-font-powerlevel10k zsh-theme-powerlevel10k-git

echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc

# Make bspwmrc file executable
echo "Making bspwmrc file executable..."
chmod +x "$CONFIG_DIR/bspwm/bspwmrc"

# Ensure all config files are writable
chmod 777 "$CONFIG_DIR/bspwm/bspwmrc" "$CONFIG_DIR/sxhkd/sxhkdrc" "$CONFIG_DIR/picom/picom.conf" "$CONFIG_DIR/polybar/config.ini" "$CONFIG_DIR/dunst/dunstrc"

echo "Configuration complete. Please restart your terminal or run 'exec zsh' to apply the changes."

# Credits
echo "Credits to: https://cheatsheetfactory.geekyhacker.com/linux/arch-lightdm"
echo "YouTube video: https://www.youtube.com/watch?v=Vu5RRz11yD8 (Developer: https://github.com/DaarcyDev)"


