#!/bin/bash

# ArchKit - Arch Linux Desktop Environment Setup
echo -e "\e[1;36m╔══════════════════════════════════════╗"
echo -e "║            \e[1;37mArchKit v2.0\e[1;36m             ║"
echo -e "║      \e[0;37mArch Linux Desktop Setup\e[1;36m      ║"
echo -e "╚══════════════════════════════════════╝\e[0m"
echo ""

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Determine actual user (works with sudo)
if [[ $EUID -eq 0 && -n "$SUDO_USER" ]]; then
    USER_NAME="$SUDO_USER"
else
    USER_NAME="$USER"
fi
CONFIG_DIR="/home/$USER_NAME/.config"
BACKUP_DIR="/home/$USER_NAME/.config_backup_$(date +%Y%m%d_%H%M%S)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${CYAN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Function to display a progress bar
show_progress() {
    local current=$1
    local total=$2
    local bar_length=40
    local percent=$(( current * 100 / total ))
    local filled=$(( current * bar_length / total ))
    local empty=$(( bar_length - filled ))
    local bar=$(printf "%-${filled}s" "=")
    local spaces=$(printf "%-${empty}s" " ")

    printf "\r${CYAN}[%-40s]${NC} %d%%" "${bar// /=}${spaces}" "$percent"
}

# Function to ask for user confirmation
ask_confirmation() {
    local message=$1
    local default=${2:-"y"}
    
    if [[ $default == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    echo -ne "${YELLOW}$message $prompt: ${NC}"
    read -r response
    
    if [[ -z $response ]]; then
        response=$default
    fi
    
    [[ $response =~ ^[Yy]$ ]]
}

# Function to backup existing files
backup_file() {
    local file_path=$1
    if [[ -f "$file_path" || -d "$file_path" ]]; then
        log_warning "Existing configuration found: $file_path"
        if ask_confirmation "Do you want to backup and replace it?"; then
            mkdir -p "$BACKUP_DIR"
            cp -r "$file_path" "$BACKUP_DIR/"
            log_success "Backed up to: $BACKUP_DIR/$(basename "$file_path")"
            return 0
        else
            log "Skipping: $file_path"
            return 1
        fi
    fi
    return 0
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        # Allow root in TTY environments (common for system setup)
        if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
            log_warning "Running as root in TTY environment - this is acceptable for system setup"
            export SUDO_USER_NAME="${SUDO_USER:-$USER}"
            [[ -z "$SUDO_USER_NAME" || "$SUDO_USER_NAME" == "root" ]] && { log_error "Cannot determine target user. Please run as: sudo -u username $0"; exit 1; }
        else
            log_error "This script should not be run as root in graphical environments!"
            exit 1
        fi
    fi
}

# Detect TTY environment
detect_environment() {
    [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]] && export RUNNING_IN_TTY=true && log "Running in TTY environment" || { export RUNNING_IN_TTY=false; log "Running in graphical environment"; }
}

# Verify user environment
verify_user_environment() {
    log "Verifying user environment..."
    
    # When running as root via sudo, check the actual user
    if [[ $EUID -eq 0 ]]; then
        log "Running as root - target user: $USER_NAME"
        [[ ! -d "/home/$USER_NAME" ]] && log_error "Home directory /home/$USER_NAME does not exist!" && exit 1
        # Create home directory if it doesn't exist (shouldn't happen but just in case)
        mkdir -p "/home/$USER_NAME" 2>/dev/null || true
    else
        [[ "$USER" != "$USER_NAME" ]] && log_warning "Script user ($USER) differs from target user ($USER_NAME)"
        [[ ! -d "/home/$USER_NAME" ]] && log_error "Home directory /home/$USER_NAME does not exist!" && exit 1
        [[ ! -w "/home/$USER_NAME" ]] && log_error "No write permission to /home/$USER_NAME" && exit 1
    fi
    
    log_success "User environment verified"
}

# Check internet connectivity
check_internet() {
    log "Checking internet connectivity..."
    ping -c 1 archlinux.org &> /dev/null && log_success "Internet connection verified" || { log_error "No internet connection. Please check your network."; exit 1; }
}

# Update system
update_system() {
    log "Updating system packages..."
    sudo pacman -Syu --noconfirm && log_success "System updated successfully" || { log_error "Failed to update system"; exit 1; }
}

# Packages to install (alacritty removed)
packages=(lightdm lightdm-gtk-greeter bspwm sxhkd polybar dunst kitty zsh neofetch firefox code feh fzf bashtop picom neovim qtile xorg-server xorg-xinit xorg-xrandr xorg-xsetroot)

# Function to install packages
install_packages() {
    local total=${#packages[@]}
    local current=0
    local failed_packages=()

    log "Installing packages..."
    echo ""

    for package in "${packages[@]}"; do
        printf "${BLUE}Installing:${NC} %-20s " "$package"
        
        # Try to install the package
        if sudo pacman -S --noconfirm --needed "$package" &> /dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            failed_packages+=("$package")
        fi
        
        current=$((current + 1))
        show_progress $current $total
        sleep 0.5
    done

    echo ""
    
    # Display results
    if [ ${#failed_packages[@]} -eq 0 ]; then
        log_success "All packages installed successfully"
    else
        log_warning "Failed to install: ${failed_packages[*]}"
        if ask_confirmation "Do you want to continue anyway?"; then
            log "Continuing with installation..."
        else
            log_error "Installation aborted"
            exit 1
        fi
    fi
}

# Function to enable and configure LightDM
setup_lightdm() {
    log "Configuring LightDM display manager..."
    
    # Enable LightDM service
    if sudo systemctl enable lightdm.service; then
        log_success "LightDM service enabled"
    else
        log_error "Failed to enable LightDM service"
        return 1
    fi
    
    # Configure LightDM greeter and session
    local lightdm_conf="/etc/lightdm/lightdm.conf"
    if [[ -f "$lightdm_conf" ]]; then
        # Backup original config
        sudo cp "$lightdm_conf" "$lightdm_conf.backup"
        
        # Configure greeter session
        sudo sed -i 's/#greeter-session=.*/greeter-session=lightdm-gtk-greeter/' "$lightdm_conf"
        
        # Configure user session (important for TTY execution)
        sudo sed -i 's/#user-session=.*/user-session=bspwm/' "$lightdm_conf"
        
        # Enable autologin if requested (optional)
        if [[ "$RUNNING_IN_TTY" == "true" ]]; then
            log "TTY detected - configuring additional LightDM settings..."
            sudo sed -i "s/#autologin-user=.*/autologin-user=$USER_NAME/" "$lightdm_conf"
            sudo sed -i 's/#autologin-user-timeout=.*/autologin-user-timeout=0/' "$lightdm_conf"
        fi
        
        log_success "LightDM configuration updated"
    fi
    
    # Create desktop session file for bspwm
    local session_file="/usr/share/xsessions/bspwm.desktop"
    if [[ ! -f "$session_file" ]]; then
        sudo tee "$session_file" > /dev/null << 'EOF'
[Desktop Entry]
Name=bspwm
Comment=Binary space partitioning window manager
Exec=bspwm
Type=Application
Keywords=wm;tiling
EOF
        log_success "Created bspwm desktop session file"
    fi
    
    # Create .xsession file to fix black screen issue
    local xsession_file="/home/$USER_NAME/.xsession"
    if backup_file "$xsession_file"; then
        cat > "$xsession_file" << 'EOF'
#!/bin/bash
# Fix for black screen after login - optimized for TTY execution
export XDG_CURRENT_DESKTOP=bspwm
export XDG_SESSION_DESKTOP=bspwm
export XDG_SESSION_TYPE=x11

# Set up environment
export PATH="$HOME/.local/bin:$PATH"

# Start sxhkd (hotkey daemon)
sxhkd &

# Start polybar
$HOME/.config/polybar/launch.sh &

# Start compositor
picom &

# Start notification daemon
dunst &

# Set wallpaper
feh --bg-scale $HOME/.config/wallpaper/onigirl.png &

# Start bspwm
exec bspwm
EOF
        chmod +x "$xsession_file"
        chown "$USER_NAME:$USER_NAME" "$xsession_file"
        log_success "Created enhanced .xsession file for TTY compatibility"
    fi
    
    # Create .xinitrc as backup
    local xinitrc_file="/home/$USER_NAME/.xinitrc"
    if backup_file "$xinitrc_file"; then
        cat > "$xinitrc_file" << 'EOF'
#!/bin/bash
# Start X session - backup method
exec $HOME/.xsession
EOF
        chmod +x "$xinitrc_file"
        chown "$USER_NAME:$USER_NAME" "$xinitrc_file"
        log_success "Created .xinitrc backup file"
    fi
}

# Create configuration directories
create_directories() {
    log "Creating configuration directories..."
    local directories=(bspwm sxhkd polybar polybar/scripts picom dunst kitty wallpaper p10k)
    for dir in "${directories[@]}"; do
        local full_path="$CONFIG_DIR/$dir"
        [[ ! -d "$full_path" ]] && mkdir -p "$full_path" && chown -R "$USER_NAME:$USER_NAME" "$full_path" && chmod -R 755 "$full_path"
    done
    log_success "Configuration directories created"
}

# Copy configuration files
copy_configurations() {
    log "Copying configuration files..."
    
    local config_mappings=("bspwm:$CONFIG_DIR/bspwm" "sxhkd:$CONFIG_DIR/sxhkd" "polybar:$CONFIG_DIR/polybar" "kitty:$CONFIG_DIR/kitty" "wallpaper:$CONFIG_DIR/wallpaper" "p10k/.p10k.zsh:$CONFIG_DIR/.p10k.zsh" ".zshrc:/home/$USER_NAME/.zshrc")
    
    for mapping in "${config_mappings[@]}"; do
        local source="${mapping%:*}" dest="${mapping#*:}" source_path="$SCRIPT_DIR/$source"
        if [[ -e "$source_path" ]]; then
            if backup_file "$dest"; then
                [[ -d "$source_path" ]] && cp -r "$source_path/." "$dest/" || cp "$source_path" "$dest"
                chown -R "$USER_NAME:$USER_NAME" "$dest" && log_success "Copied: $source → $dest"
            fi
        else
            log_warning "Source not found: $source_path"
        fi
    done
    
    # Copy fonts and system configs
    [[ -d "$SCRIPT_DIR/polybar/fonts" ]] && sudo cp -r "$SCRIPT_DIR/polybar/fonts/." "/usr/share/fonts/" && sudo fc-cache -fv &> /dev/null && log_success "Fonts installed"
    [[ ! -f "$CONFIG_DIR/picom/picom.conf" && -f "/etc/xdg/picom.conf" ]] && cp "/etc/xdg/picom.conf" "$CONFIG_DIR/picom/picom.conf" && log_success "Copied default picom config"
    [[ ! -f "$CONFIG_DIR/dunst/dunstrc" && -f "/etc/dunst/dunstrc" ]] && cp "/etc/dunst/dunstrc" "$CONFIG_DIR/dunst/dunstrc" && log_success "Copied default dunst config"
}

# Set comprehensive file permissions
set_permissions() {
    log "Setting file permissions and ownership..."
    
    # Set directory permissions (755)
    find "/home/$USER_NAME/.config" -type d -exec chmod 755 {} \; 2>/dev/null
    find "/home/$USER_NAME/.local" -type d -exec chmod 755 {} \; 2>/dev/null
    
    # Set config file permissions (644)
    find "/home/$USER_NAME/.config" -type f -exec chmod 644 {} \; 2>/dev/null
    find "/home/$USER_NAME/.local" -type f -exec chmod 644 {} \; 2>/dev/null
    
    # Set executable permissions (755)
    local executables=("$CONFIG_DIR/bspwm/bspwmrc" "$CONFIG_DIR/polybar/launch.sh" "$CONFIG_DIR/polybar/scripts/"*.sh "/home/$USER_NAME/.zshrc")
    for file in "${executables[@]}"; do [[ -f "$file" ]] && chmod +x "$file"; done
    
    # Set ownership recursively
    chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME/.config" "/home/$USER_NAME/.local" "/home/$USER_NAME/.zshrc" "/home/$USER_NAME/.p10k.zsh" 2>/dev/null
    
    log_success "Permissions and ownership configured"
}

# Setup zsh and Oh My Zsh
setup_zsh() {
    log "Setting up Zsh..."
    
    # Install Oh My Zsh if not present
    if [[ ! -d "/home/$USER_NAME/.oh-my-zsh" ]]; then
        log "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh My Zsh installed"
    fi
    
    # Change default shell to zsh
    ask_confirmation "Change default shell to zsh?" && chsh -s "$(which zsh)" "$USER_NAME" && log_success "Default shell changed to zsh"
}

# Main installation function
main() {
    echo -e "${CYAN}Starting ArchKit installation...${NC}\n"
    
    # Pre-installation checks
    check_root
    detect_environment
    verify_user_environment
    check_internet
    
    # Show environment info
    if [[ "$RUNNING_IN_TTY" == "true" ]]; then
        log_warning "Running in TTY mode - optimized configurations will be applied"
        echo -e "${YELLOW}Note: After reboot, you'll login through LightDM graphical interface${NC}"
    fi
    
    # Installation steps
    update_system
    install_packages
    setup_lightdm
    create_directories
    copy_configurations
    set_permissions
    setup_zsh
    
    # Final message
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════╗"
    echo -e "║         Installation Complete!       ║"
    echo -e "╚══════════════════════════════════════╝${NC}"
    echo ""
    log_success "ArchKit installation completed successfully!"
    echo ""
    
    # TTY-specific instructions
    if [[ "$RUNNING_IN_TTY" == "true" ]]; then
        log "TTY Installation - Next steps:"
        echo "  1. Reboot your system: ${CYAN}sudo reboot${NC}"
        echo "  2. System will boot to LightDM login screen"
        echo "  3. Login with your username and password"
        echo "  4. bspwm desktop environment will start automatically"
        echo ""
        log_warning "Important: The graphical environment will be different from this TTY"
    else
        log "Graphical Installation - Next steps:"
        echo "  1. Reboot your system: ${CYAN}sudo reboot${NC}"
        echo "  2. Login through LightDM"
        echo "  3. Your desktop environment should load automatically"
    fi
    
    echo ""
    if [[ -d "$BACKUP_DIR" ]]; then
        log "Backup files saved to: $BACKUP_DIR"
    fi
    
    echo -e "${YELLOW}Credits:${NC}"
    echo "  • Original concept: https://github.com/DaarcyDev"
    echo "  • LightDM guide: https://cheatsheetfactory.geekyhacker.com/linux/arch-lightdm"
    echo ""
}

# Run main function
main "$@"

