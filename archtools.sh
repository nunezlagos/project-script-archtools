#!/bin/bash

echo -e "\e[1;32m
   ██████╗ ███████╗██╗   ██╗███████╗██╗      ██████╗ ██████╗ ███████╗██████╗ 
   ██╔══██╗██╔════╝██║   ██║██╔════╝██║     ██╔═══██╗██╔══██╗██╔════╝██╔══██╗
   ██║  ██║█████╗  ██║   ██║█████╗  ██║     ██║   ██║██████╔╝█████╗  ██████╔╝
   ██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║     ██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗
   ██████╔╝███████╗ ╚████╔╝ ███████╗███████╗╚██████╔╝██║     ███████╗██║  ██║
   ╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝╚══════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝                     
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
    local bar_length=50
    local percent=$(( current * 100 / total ))
    local filled=$(( current * bar_length / total ))
    local empty=$(( bar_length - filled ))
    local bar=$(printf "%-${filled}s" "=")
    local spaces=$(printf "%-${empty}s" " ")

    printf "\r[%-50s] %d%%" "${bar// /=}${spaces}" "$percent"
}

# Function to display a header
show_header() {
    local message=$1
    echo -e "\n\033[1;34m[Archtools@by Jumper]\033[0m $message\n"
}

# Packages to install
packages=(lightdm lightdm-gtk-greeter bspwm sxhkd polybar dunst kitty zsh neofetch firefox code feh fzf bashtop picom neovim )

total=${#packages[@]}
current=0

# Show header
show_header "Installing Packages"

# Install packages with progress display
for package in "${packages[@]}"; do
    sudo pacman -S --noconfirm $package &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "\nFailed to install $package"
        exit 1
    fi
    current=$((current + 1))
    show_progress $current $total
    sleep 1
done

# Enable LightDM
show_header "Enabling LightDM"
sudo systemctl enable lightdm.service &> /dev/null
sudo systemctl start lightdm.service &> /dev/null
show_progress 1 1
sleep 1

# User and config directories
USER_NAME="$USER"
CONFIG_DIR="/home/$USER_NAME/.config"
ARCHTOOLS_DIR="/Downloads/archtools"

# Create and set permissions for configuration directories
show_header "Creating Configuration Directories"
directories=(bspwm sxhkd polybar polybar/scripts picom dunst kitty wallpaper p10k)
for dir in "${directories[@]}"; do
    mkdir -p "$CONFIG_DIR/$dir"
    sudo chown -R :$USER_NAME "$CONFIG_DIR/$dir"
    sudo chmod -R 775 "$CONFIG_DIR/$dir"
done

show_progress 1 1
sleep 1

# Copy default configurations with correct permissions
show_header "Copying Default Configurations"
sudo cp -rv "$ARCHTOOLS_DIR/bspwm/." "$CONFIG_DIR/bspwm/" &> /dev/null
sudo cp -rv "$ARCHTOOLS_DIR/sxhkd/." "$CONFIG_DIR/sxhkd/" &> /dev/null
sudo cp -rv "$ARCHTOOLS_DIR/polybar/." "$CONFIG_DIR/polybar/" &> /dev/null
sudo cp -rv "$ARCHTOOLS_DIR/kitty/." "$CONFIG_DIR/kitty/" &> /dev/null
sudo cp -rv "$ARCHTOOLS_DIR/wallpaper/." "$CONFIG_DIR/wallpaper/" &> /dev/null
sudo cp -rv "$ARCHTOOLS_DIR/polybar/fonts/." "/usr/share/fonts/" &> /dev/null
sudo cp -v /etc/xdg/picom.conf "$CONFIG_DIR/picom/picom.conf" &> /dev/null
sudo cp -v /etc/dunst/dunstrc "$CONFIG_DIR/dunst/dunstrc" &> /dev/null
sudo cp -rv "$ARCHTOOLS_DIR/p10k/.p10k.zsh" "$CONFIG_DIR" &> /dev/null
show_progress 1 1
sleep 1

# Make bspwmrc file executable
show_header "Setting Executable Permissions"
sudo chmod +x "$CONFIG_DIR/bspwm/bspwmrc"
sudo chmod +x "$CONFIG_DIR/polybar/launch.sh"
sudo chmod +x "$CONFIG_DIR/polybar/scripts/focus_browser.sh"
sudo chmod +x "$CONFIG_DIR/polybar/scripts/focus_code.sh"
sudo chmod +x "$CONFIG_DIR/sxhkd/sxhkdrc"
show_progress 1 1
sleep 1

# Change shell to zsh for the current user
show_header "Setting Up Zsh"
sudo cp -v "$ARCHTOOLS_DIR/.zshrc" "/home/$USER_NAME/" &> /dev/null
sudo chmod +x "/home/$USER_NAME/.zshrc"
# chsh -s $(which zsh) $USER_NAME &> /dev/null
show_progress 1 1
sleep 1

# Final message
show_header "Configuration Complete"
echo -e "\nConfiguration complete. Please restart your terminal or run 'exec zsh' to apply the changes.\n"

# Credits
show_header "Credits"
echo -e "\nCredits to: https://cheatsheetfactory.geekyhacker.com/linux/arch-lightdm"
echo -e "YouTube video: https://www.youtube.com/watch?v=Vu5RRz11yD8 (Developer: https://github.com/DaarcyDev)"
