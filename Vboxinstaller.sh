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

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

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
packages=(lightdm lightdm-gtk-greeter bspwm sxhkd polybar picom dunst alacritty zsh)

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
echo "Creating configuration directories..."
mkdir -p ~/.config/bspwm
mkdir -p ~/.config/sxhkd
mkdir -p ~/.config/polybar
mkdir -p ~/.config/picom
mkdir -p ~/.config/dunst
mkdir -p ~/.config/alacritty

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

# Update sxhkdrc with necessary changes
echo "Updating sxhkdrc..."
cat <<EOL > ~/.config/sxhkd/sxhkdrc
# terminal emulator
super + Return
	alacritty

# Open Firefox
super + b
	firefox
EOL

# Configure bspwmrc
echo "Configuring bspwmrc..."
cat <<EOL > ~/.config/bspwm/bspwmrc
#!/bin/bash

# Start sxhkd, dunst, and polybar
sxhkd &
dunst &
polybar &

# Remove specific rules
bspc rule -a Gimp desktop='^8' state=floating follow=on
bspc rule -a Chromium desktop='^2'
bspc rule -a mplayer2 state=floating
bspc rule -a Kupfer.py focus=on
bspc rule -a Screenkey manage=off
EOL

echo "Configuration complete. Please restart your terminal or run 'exec zsh' to apply the changes."

# Credits
echo "Credits to: https://cheatsheetfactory.geekyhacker.com/linux/arch-lightdm"
echo "YouTube video: https://www.youtube.com/watch?v=Vu5RRz11yD8 (Developer: https://github.com/DaarcyDev)"

