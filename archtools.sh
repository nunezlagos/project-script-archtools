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
packages=(lightdm lightdm-gtk-greeter bspwm sxhkd polybar picom dunst kitty zsh neofetch firefox code)

total=${#packages[@]}
current=0

# Install packages with progress display
for package in "${packages[@]}"; do
    echo "Installing $package..."
    sudo pacman -S --noconfirm $package
    if [ $? -ne 0 ]; then
        echo "Failed to install $package"
        exit 1
    fi
    current=$((current + 1))
    show_progress $current $total
done

# Enable LightDM
echo -e "\nEnabling LightDM..."
sudo systemctl enable lightdm.service
sudo systemctl start lightdm.service

# User and config directories
USER_NAME="$USER"
CONFIG_DIR="/home/$USER_NAME/.config"
ARCHTOOLS_DIR="/tmp/archtools"

# Create and set permissions for configuration directories
echo "Creating and setting permissions for configuration directories..."

mkdir -p "$CONFIG_DIR/bspwm" "$CONFIG_DIR/sxhkd" "$CONFIG_DIR/polybar" "$CONFIG_DIR/picom" "$CONFIG_DIR/dunst" "$CONFIG_DIR/polybar/scripts" "$CONFIG_DIR/kitty"
sudo chmod 755 "$CONFIG_DIR" "$CONFIG_DIR/bspwm" "$CONFIG_DIR/sxhkd" "$CONFIG_DIR/polybar" "$CONFIG_DIR/picom" "$CONFIG_DIR/dunst" "$CONFIG_DIR/polybar/scripts" "$CONFIG_DIR/kitty"

# Copy default configurations
echo "Copying default configurations..."
sudo cp -rv "$ARCHTOOLS_DIR/bspwm/." "$CONFIG_DIR/bspwm/"
sudo cp -rv "$ARCHTOOLS_DIR/sxhkd/." "$CONFIG_DIR/sxhkd/"
sudo cp -rv "$ARCHTOOLS_DIR/polybar/." "$CONFIG_DIR/polybar/"
sudo cp -rv "$ARCHTOOLS_DIR/kitty/." "$CONFIG_DIR/kitty/"
sudo cp -rv "$ARCHTOOLS_DIR/polybar/fonts/." "/usr/share/fonts/"
sudo cp -v /etc/xdg/picom.conf "$CONFIG_DIR/picom/"
sudo cp -v /etc/dunst/dunstrc "$CONFIG_DIR/dunst/"

# Make bspwmrc file executable
echo "Making bspwmrc file executable..."
chmod +x "$CONFIG_DIR/bspwm/bspwmrc"

# Install yay for AUR packages without interaction
echo "Installing yay..."
sudo pacman -S --needed --noconfirm git base-devel
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm
cd -

# Ensure yay does not prompt for any confirmation
yay --save --answerclean None --answerdiff None --answeredit None

# Install powerlevel10k theme
echo "Installing powerlevel10k theme..."
yay -Sy --noconfirm ttf-meslo-nerd-font-powerlevel10k zsh-theme-powerlevel10k-git

# Install Brave browser
echo "Installing Brave browser..."
yay -S --noconfirm brave-bin

# Install oh-my-zsh
echo "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Change shell to zsh for the current user
echo "Changing shell to zsh..."
chsh -s $(which zsh) $USER_NAME

# Ensure all config files are writable
sudo chmod 755 "$CONFIG_DIR/bspwm/bspwmrc" "$CONFIG_DIR/sxhkd/sxhkdrc" "$CONFIG_DIR/picom/picom.conf" "$CONFIG_DIR/polybar/config.ini" "$CONFIG_DIR/dunst/dunstrc"

# Set powerlevel10k theme in .zshrc
echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc

echo "Configuration complete. Please restart your terminal or run 'exec zsh' to apply the changes."

# Credits
echo "Credits to: https://cheatsheetfactory.geekyhacker.com/linux/arch-lightdm"
echo "YouTube video: https://www.youtube.com/watch?v=Vu5RRz11yD8 (Developer: https://github.com/DaarcyDev)"



