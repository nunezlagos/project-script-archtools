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

## Install and enable LightDM login manager
echo "Installing and enabling LightDM..."
sudo pacman -Sy --noconfirm lightdm
sudo systemctl enable lightdm.service

# Install LightDM greeter to avoid errors
echo "Installing LightDM greeter..."
sudo pacman -Sy --noconfirm lightdm-gtk-greeter

# Install required packages
echo "Installing bspwm, sxhkd, Polybar, Picom, Dunst, Alacritty, and Zsh..."
sudo pacman -S --noconfirm bspwm sxhkd polybar picom dunst alacritty zsh

# Create configuration directories
echo "Creating configuration directories..."
mkdir -p ~/.config/bspwm
mkdir -p ~/.config/sxhkd
mkdir -p ~/.config/polybar
mkdir -p ~/.config/picom
mkdir -p ~/.config/dunst

# Copy default configurations
echo "Copying default configurations..."
cp /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/
cp /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/
cp /etc/xdg/picom.conf ~/.config/picom/
cp /etc/polybar/config.ini ~/.config/polybar/
cp /etc/dunst/dunstrc ~/.config/dunst/

# Make the bspwmrc file executable
echo "Making the bspwmrc file executable..."
chmod +x ~/.config/bspwm/bspwmrc

# Configure Alacritty to use Zsh
echo "Configuring Alacritty to use Zsh..."
mkdir -p ~/.config/alacritty
cat <<EOL > ~/.config/alacritty/alacritty.yml
shell:
  program: /usr/bin/zsh
  args:
    - --login
EOL

# Install Oh-My-Zsh
echo "Installing Oh-My-Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Configure Oh-My-Zsh theme to 'agnoster'
echo "Configuring Oh-My-Zsh theme to 'agnoster'..."
sed -i 's/ZSH_THEME=".*"/ZSH_THEME="agnoster"/' ~/.zshrc

echo "Configuration complete. Please restart your terminal or run 'exec zsh' to apply the changes."

# Credits
echo "Credits to: https://cheatsheetfactory.geekyhacker.com/linux/arch-lightdm"
echo "YouTube video: https://www.youtube.com/watch?v=Vu5RRz11yD8 (Developer: https://github.com/DaarcyDev)"

