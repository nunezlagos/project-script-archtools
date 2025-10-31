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
    local item_name=${3:-"elemento"}
    local bar_length=40
    local percent=$(( current * 100 / total ))
    local filled=$(( current * bar_length / total ))
    local empty=$(( bar_length - filled ))
    local bar=$(printf "%-${filled}s" "=")
    local spaces=$(printf "%-${empty}s" " ")

    printf "\r${CYAN}[%-40s]${NC} %d%% ${YELLOW}(%d/%d)${NC} ${GREEN}%s${NC}" "${bar// /=}${spaces}" "$percent" "$current" "$total" "$item_name"
}

# Function to ask for user confirmation
ask_confirmation() {
    local message=$1
    local default=${2:-"y"}
    
    # Modo automático: siempre responde "sí" y solo informa
    log_success "AUTO: $message - Respondiendo automáticamente: SÍ"
    return 0  # Siempre retorna verdadero (sí)
}

# Function to backup existing files
backup_file() {
    local file_path=$1
    if [[ -f "$file_path" || -d "$file_path" ]]; then
        log_warning "Existing configuration found: $file_path"
        mkdir -p "$BACKUP_DIR"
        cp -r "$file_path" "$BACKUP_DIR/" 2>/dev/null
        log_success "Backed up to: $BACKUP_DIR/$(basename "$file_path")"
        return 0
    fi
    return 0
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        # Since we assume 100% TTY execution, root is expected and acceptable
        log_warning "Running as root in TTY environment - this is expected for system setup"
        export SUDO_USER_NAME="${SUDO_USER:-$USER}"
        
        # Validate that we have a target user
        if [[ -z "$SUDO_USER_NAME" || "$SUDO_USER_NAME" == "root" ]]; then
            log_error "Cannot determine target user. Please run as: sudo -u username $0"
            log_error "Or create a user first with: useradd -m -G wheel username"
            exit 1
        fi
        
        log "Target user for configuration: $SUDO_USER_NAME"
    else
        log "Running as regular user: $USER"
    fi
}

# Detect TTY environment (assume 100% TTY)
detect_environment() {
    # Force TTY mode since we assume 100% TTY execution
    export RUNNING_IN_TTY=true
    log "Forced TTY mode - optimized for terminal installation"
    
    # Additional TTY-specific environment setup
    export XDG_RUNTIME_DIR="/run/user/$(id -u $USER_NAME)"
    export XDG_CONFIG_HOME="/home/$USER_NAME/.config"
    export XDG_DATA_HOME="/home/$USER_NAME/.local/share"
    export XDG_CACHE_HOME="/home/$USER_NAME/.cache"
    
    log "XDG directories configured for user: $USER_NAME"
}

# Enhanced user environment verification for TTY
verify_user_environment() {
    log "Verifying user environment for TTY installation..."
    
    # Ensure target user exists
    if ! id "$USER_NAME" &>/dev/null; then
        log_error "User '$USER_NAME' does not exist!"
        log "Please create the user first:"
        log "  sudo useradd -m -G wheel $USER_NAME"
        log "  sudo passwd $USER_NAME"
        exit 1
    fi
    
    # Check if user is in wheel group (for sudo access)
    if ! groups "$USER_NAME" | grep -q wheel; then
        log_warning "User '$USER_NAME' is not in wheel group"
        sudo usermod -aG wheel "$USER_NAME"
        log_success "User added to wheel group"
    fi
    
    # Verify home directory exists and is accessible
    local user_home="/home/$USER_NAME"
    if [[ ! -d "$user_home" ]]; then
        log_error "Home directory $user_home does not exist!"
        log "Creating home directory..."
        sudo mkdir -p "$user_home"
        sudo chown "$USER_NAME:$USER_NAME" "$user_home"
        sudo chmod 755 "$user_home"
        log_success "Home directory created"
    fi
    
    # Verify write permissions
    if [[ $EUID -eq 0 ]]; then
        # Running as root - we can write anywhere
        log_success "Running as root - full system access available"
    else
        # Running as user - check write permissions
        if [[ ! -w "$user_home" ]]; then
            log_error "No write permission to $user_home"
            exit 1
        fi
    fi
    
    # Create essential XDG directories
    local xdg_dirs=("$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME")
    for dir in "${xdg_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            chown -R "$USER_NAME:$USER_NAME" "$dir"
            chmod -R 755 "$dir"
            log_success "Created XDG directory: $dir"
        fi
    done
    
    # Verify sudo configuration for wheel group
    if ! sudo grep -q "^%wheel.*ALL=(ALL.*ALL" /etc/sudoers; then
        log_warning "Wheel group sudo access not configured"
        echo "%wheel ALL=(ALL) ALL" | sudo tee -a /etc/sudoers > /dev/null
        log_success "Sudo access configured for wheel group"
    fi
    
    log_success "User environment verified and configured for TTY installation"
}

# Check internet connectivity
check_internet() {
    log "Checking internet connectivity..."
    ping -c 1 archlinux.org &> /dev/null && log_success "Internet connection verified" || { log_error "No internet connection. Please check your network."; exit 1; }
}

# Verify package installation
verify_package_installed() {
    local package=$1
    pacman -Qi "$package" &> /dev/null
}

# Verify all required packages are installed
verify_packages() {
    log "Verifying installed packages..."
    local missing_packages=()
    local total=${#packages[@]}
    local current=0
    
    for package in "${packages[@]}"; do
        printf "${BLUE}Checking:${NC} %-20s " "$package"
        
        if verify_package_installed "$package"; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            missing_packages+=("$package")
        fi
        
        current=$((current + 1))
        show_progress $current $total "Verificando $package"
        sleep 0.1
    done
    
    echo ""
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        log_success "All required packages are installed"
        return 0
    else
        log_error "Missing packages: ${missing_packages[*]}"
        log "These packages need to be installed before configuration"
        return 1
    fi
}

# Verify critical system services
verify_services() {
    log "Verifying system services..."
    local services=("systemd" "dbus")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log_success "Service $service is running"
        else
            log_warning "Service $service is not running"
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        log_warning "Some services are not running: ${failed_services[*]}"
        log "This may cause issues but installation will continue"
    fi
}

# Verify source configuration files exist
verify_source_configs() {
    log "Verifying source configuration files..."
    local required_configs=("bspwm/bspwmrc" "sxhkd/sxhkdrc" "polybar/workspace.ini" "kitty/kitty.conf")
    local missing_configs=()
    
    for config in "${required_configs[@]}"; do
        local config_path="$SCRIPT_DIR/$config"
        if [[ -f "$config_path" ]]; then
            log_success "Found: $config"
        else
            log_error "Missing: $config"
            missing_configs+=("$config")
        fi
    done
    
    if [ ${#missing_configs[@]} -gt 0 ]; then
        log_error "Missing configuration files: ${missing_configs[*]}"
        log_error "Please ensure all configuration files are present in the script directory"
        return 1
    fi
    
    log_success "All source configuration files verified"
    return 0
}

# Function to validate critical system services
validate_critical_services() {
    log "Validating critical system services for BSPWM installation..."
    local validation_failed=false
    
    # Check systemd is running
    if ! systemctl is-system-running >/dev/null 2>&1; then
        log_error "systemd is not running properly"
        validation_failed=true
    else
        log_success "systemd is running"
    fi
    
    # Check dbus service
    if ! systemctl is-active --quiet dbus; then
        log_error "dbus service is not active"
        validation_failed=true
    else
        log_success "dbus service is active"
    fi
    
    # Check if X11 is available (Xorg)
    if ! command -v Xorg >/dev/null 2>&1; then
        log_error "Xorg (X11 server) is not installed"
        validation_failed=true
    else
        log_success "Xorg is available"
    fi
    
    # Check for graphics drivers
    local gpu_driver_found=false
    
    # Check for common GPU drivers
    if lspci | grep -i "vga\|3d\|display" | grep -qi "nvidia"; then
        if command -v nvidia-smi >/dev/null 2>&1; then
            log_success "NVIDIA GPU detected with drivers"
            gpu_driver_found=true
        else
            log_warning "NVIDIA GPU detected but drivers may not be installed"
        fi
    elif lspci | grep -i "vga\|3d\|display" | grep -qi "amd\|ati"; then
        if lsmod | grep -q "amdgpu\|radeon"; then
            log_success "AMD GPU detected with drivers loaded"
            gpu_driver_found=true
        else
            log_warning "AMD GPU detected but drivers may not be loaded"
        fi
    elif lspci | grep -i "vga\|3d\|display" | grep -qi "intel"; then
        if lsmod | grep -q "i915\|intel"; then
            log_success "Intel GPU detected with drivers loaded"
            gpu_driver_found=true
        else
            log_warning "Intel GPU detected but drivers may not be loaded"
        fi
    fi
    
    if ! $gpu_driver_found; then
        log_warning "No specific GPU drivers detected - using generic drivers"
    fi
    
    # Check network connectivity for package downloads
    if ! ping -c 1 archlinux.org >/dev/null 2>&1; then
        log_error "No internet connectivity to Arch Linux repositories"
        validation_failed=true
    else
        log_success "Internet connectivity verified"
    fi
    
    # Check pacman database
    if ! sudo pacman -Sy >/dev/null 2>&1; then
        log_error "Failed to sync pacman database"
        validation_failed=true
    else
        log_success "Pacman database synced successfully"
    fi
    
    # Check available disk space (minimum 2GB free)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local min_space=2097152  # 2GB in KB
    
    if [[ $available_space -lt $min_space ]]; then
        log_error "Insufficient disk space. Available: $(($available_space/1024))MB, Required: 2GB"
        validation_failed=true
    else
        log_success "Sufficient disk space available: $(($available_space/1024/1024))GB"
    fi
    
    # Check if running as root or with sudo access
    if [[ $EUID -eq 0 ]]; then
        log_success "Running with root privileges"
    elif sudo -n true 2>/dev/null; then
        log_success "Sudo access verified"
    else
        log_error "No root privileges or sudo access"
        validation_failed=true
    fi
    
    # TTY-specific validations
    if [[ "$RUNNING_IN_TTY" == "true" ]]; then
        log "Performing TTY-specific validations..."
        
        # Check if we can create X session files
        local test_file="/tmp/archkit_x_test_$$"
        if touch "$test_file" 2>/dev/null; then
            rm -f "$test_file"
            log_success "File system write permissions verified"
        else
            log_error "Cannot write to file system"
            validation_failed=true
        fi
        
        # Check if target user can be switched to
        if sudo -u "$USER_NAME" whoami >/dev/null 2>&1; then
            log_success "Can switch to target user: $USER_NAME"
        else
            log_error "Cannot switch to target user: $USER_NAME"
            validation_failed=true
        fi
        
        # Verify XDG directories can be created
        local xdg_test_dir="/home/$USER_NAME/.config/test_$$"
        if sudo -u "$USER_NAME" mkdir -p "$xdg_test_dir" 2>/dev/null; then
            sudo -u "$USER_NAME" rmdir "$xdg_test_dir" 2>/dev/null
            log_success "XDG directory creation verified"
        else
            log_error "Cannot create XDG directories for user $USER_NAME"
            validation_failed=true
        fi
    fi
    
    if $validation_failed; then
        log_error "Critical service validation failed!"
        return 1
    else
        log_success "All critical services validated successfully"
        return 0
    fi
}

# Function to validate X11 and display capabilities
validate_x11_display() {
    log "Validating X11 display capabilities..."
    
    # Check if X11 packages are installed
    local x11_packages=("xorg-server" "xorg-xinit" "xorg-xauth")
    local missing_x11=()
    
    for pkg in "${x11_packages[@]}"; do
        if ! verify_package_installed "$pkg"; then
            missing_x11+=("$pkg")
        fi
    done
    
    if [[ ${#missing_x11[@]} -gt 0 ]]; then
        log_error "Missing X11 packages: ${missing_x11[*]}"
        return 1
    else
        log_success "Essential X11 packages are installed"
    fi
    
    # Check if we can start a test X session (only if not already in X)
    if [[ -z "$DISPLAY" ]]; then
        log "Testing X11 server startup capability..."
        
        # Test if X can start (dry run)
        if Xorg -version >/dev/null 2>&1; then
            log_success "Xorg can be executed"
        else
            log_error "Xorg cannot be executed properly"
            return 1
        fi
        
        # Check for input devices
        if ls /dev/input/event* >/dev/null 2>&1; then
            log_success "Input devices detected"
        else
            log_warning "No input devices detected - keyboard/mouse may not work"
        fi
        
        # Check for graphics devices
        if ls /dev/dri/* >/dev/null 2>&1; then
            log_success "Graphics devices detected in /dev/dri/"
        else
            log_warning "No graphics devices in /dev/dri/ - may use software rendering"
        fi
    else
        log_success "Already running in X11 session: $DISPLAY"
    fi
    
    return 0
}

# Function to validate window manager dependencies
validate_wm_dependencies() {
    log "Validating window manager dependencies..."
    
    # Essential WM packages
    local wm_packages=("bspwm" "sxhkd")
    local missing_wm=()
    
    for pkg in "${wm_packages[@]}"; do
        if ! verify_package_installed "$pkg"; then
            missing_wm+=("$pkg")
        fi
    done
    
    if [[ ${#missing_wm[@]} -gt 0 ]]; then
        log_error "Missing window manager packages: ${missing_wm[*]}"
        return 1
    else
        log_success "Essential window manager packages are installed"
    fi
    
    # Check if bspwm can be executed
    if bspwm -v >/dev/null 2>&1; then
        log_success "bspwm executable is working"
    else
        log_error "bspwm executable is not working properly"
        return 1
    fi
    
    # Check if sxhkd can be executed
    if sxhkd -v >/dev/null 2>&1; then
        log_success "sxhkd executable is working"
    else
        log_error "sxhkd executable is not working properly"
        return 1
    fi
    
    # Optional but recommended packages
    local optional_packages=("polybar" "picom" "dunst" "feh" "kitty")
    local missing_optional=()
    
    for pkg in "${optional_packages[@]}"; do
        if ! verify_package_installed "$pkg"; then
            missing_optional+=("$pkg")
        fi
    done
    
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        log_warning "Missing optional packages: ${missing_optional[*]}"
        log_warning "These will be installed during the setup process"
    else
        log_success "All optional packages are already installed"
    fi
    
    return 0
}

# Function to create rollback point and implement rollback mechanism
create_rollback_point() {
    log "Creating rollback point for safe installation..."
    
    # Create rollback directory with timestamp
    ROLLBACK_DIR="/tmp/archkit_rollback_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$ROLLBACK_DIR"
    
    # Backup critical system files
    log "Backing up critical system files..."
    
    # Backup LightDM configuration
    if [[ -f "/etc/lightdm/lightdm.conf" ]]; then
        sudo cp "/etc/lightdm/lightdm.conf" "$ROLLBACK_DIR/lightdm.conf.backup"
        log_success "Backed up LightDM configuration"
    fi
    
    # Backup systemd services state
    systemctl list-unit-files --type=service --state=enabled > "$ROLLBACK_DIR/enabled_services.txt"
    log_success "Backed up enabled services list"
    
    # Backup user's existing configurations
    local user_home="/home/$USER_NAME"
    if [[ -d "$user_home" ]]; then
        log "Backing up existing user configurations..."
        
        # Backup existing .config directory
        if [[ -d "$user_home/.config" ]]; then
            sudo -u "$USER_NAME" cp -r "$user_home/.config" "$ROLLBACK_DIR/user_config_backup" 2>/dev/null || true
            log_success "Backed up existing .config directory"
        fi
        
        # Backup existing shell configurations (sin Zsh)
        for file in ".bashrc" ".profile" ".xsession" ".xinitrc"; do
            if [[ -f "$user_home/$file" ]]; then
                sudo -u "$USER_NAME" cp "$user_home/$file" "$ROLLBACK_DIR/$file.backup" 2>/dev/null || true
            fi
        done
        log_success "Backed up shell configuration files"
    fi
    
    # Create rollback script
    cat > "$ROLLBACK_DIR/rollback.sh" << 'EOF'
#!/bin/bash
# ArchKit Rollback Script
# This script restores the system to the state before ArchKit installation

ROLLBACK_DIR="$(dirname "$0")"
USER_NAME="$1"

echo "Starting ArchKit rollback process..."

# Restore LightDM configuration
if [[ -f "$ROLLBACK_DIR/lightdm.conf.backup" ]]; then
    sudo cp "$ROLLBACK_DIR/lightdm.conf.backup" "/etc/lightdm/lightdm.conf"
    echo "Restored LightDM configuration"
fi

# Restore user configurations
if [[ -n "$USER_NAME" && -d "/home/$USER_NAME" ]]; then
    # Restore .config directory
    if [[ -d "$ROLLBACK_DIR/user_config_backup" ]]; then
        sudo -u "$USER_NAME" rm -rf "/home/$USER_NAME/.config"
        sudo -u "$USER_NAME" cp -r "$ROLLBACK_DIR/user_config_backup" "/home/$USER_NAME/.config"
        echo "Restored user .config directory"
    fi
    
    # Restore shell configurations (sin Zsh)
    for file in ".bashrc" ".profile" ".xsession" ".xinitrc"; do
        if [[ -f "$ROLLBACK_DIR/$file.backup" ]]; then
            sudo -u "$USER_NAME" cp "$ROLLBACK_DIR/$file.backup" "/home/$USER_NAME/$file"
            echo "Restored $file"
        fi
    done
fi

echo "Rollback completed. You may need to reboot the system."
echo "To remove ArchKit packages, run: sudo pacman -Rns bspwm sxhkd polybar kitty picom dunst feh"
EOF

    chmod +x "$ROLLBACK_DIR/rollback.sh"
    
    # Store rollback info
    echo "ROLLBACK_DIR=$ROLLBACK_DIR" > "/tmp/archkit_rollback_info"
    echo "USER_NAME=$USER_NAME" >> "/tmp/archkit_rollback_info"
    echo "TIMESTAMP=$(date)" >> "/tmp/archkit_rollback_info"
    
    log_success "Rollback point created at: $ROLLBACK_DIR"
    log "To rollback changes, run: $ROLLBACK_DIR/rollback.sh $USER_NAME"
    
    return 0
}

# Function to perform rollback in case of failure
perform_rollback() {
    local reason="$1"
    log_error "Installation failed: $reason"
    
    if [[ -f "/tmp/archkit_rollback_info" ]]; then
        source "/tmp/archkit_rollback_info"
        
        if [[ -f "$ROLLBACK_DIR/rollback.sh" ]]; then
            log "Performing automatic rollback due to critical error..."
            
            "$ROLLBACK_DIR/rollback.sh" "$USER_NAME"
            log_success "Rollback completed automatically"
            
            # Clean up rollback files
            rm -rf "$ROLLBACK_DIR" 2>/dev/null || true
            rm -f "/tmp/archkit_rollback_info" 2>/dev/null || true
            
            return 0
            fi
        fi
    fi
    
    log_error "No rollback point found or rollback failed"
    return 1
}

# Enhanced pre-installation checks function
run_pre_installation_checks() {
    log "Running comprehensive pre-installation checks..."
    local checks_failed=false
    local critical_failures=()
    local warnings=()
    
    # Create rollback point first
    if ! create_rollback_point; then
        log_error "Failed to create rollback point"
        return 1
    fi
    
    # Run all validation functions
    log "=== SYSTEM VALIDATION PHASE ==="
    
    # Critical service validation
    if ! validate_critical_services; then
        critical_failures+=("Critical system services validation failed")
        checks_failed=true
    fi
    
    # X11 display validation
    if ! validate_x11_display; then
        critical_failures+=("X11 display validation failed")
        checks_failed=true
    fi
    
    # Window manager dependencies validation
    if ! validate_wm_dependencies; then
        warnings+=("Window manager dependencies missing - will be installed")
    fi
    
    # Package verification
    log "=== PACKAGE VERIFICATION PHASE ==="
    local missing_packages=()
    if ! verify_packages missing_packages; then
        log_warning "Missing packages detected: ${missing_packages[*]}"
        warnings+=("Missing packages will be installed: ${missing_packages[*]}")
    fi
    
    # Service verification
    log "=== SERVICE VERIFICATION PHASE ==="
    if ! verify_services; then
        warnings+=("Some services are not running - will be configured")
    fi
    
    # Source configuration verification
    log "=== SOURCE CONFIGURATION VERIFICATION PHASE ==="
    if ! verify_source_configs; then
        critical_failures+=("Source configuration files missing or invalid")
        checks_failed=true
    fi
    
    # User environment verification
    log "=== USER ENVIRONMENT VERIFICATION PHASE ==="
    if ! verify_user_environment; then
        critical_failures+=("User environment validation failed")
        checks_failed=true
    fi
    
    # Display results
    log "=== PRE-INSTALLATION CHECK RESULTS ==="
    
    if [[ ${#critical_failures[@]} -gt 0 ]]; then
        log_error "CRITICAL FAILURES DETECTED:"
        for failure in "${critical_failures[@]}"; do
            log_error "  - $failure"
        done
    fi
    
    if [[ ${#warnings[@]} -gt 0 ]]; then
        log_warning "WARNINGS (will be resolved during installation):"
        for warning in "${warnings[@]}"; do
            log_warning "  - $warning"
        done
    fi
    
    if $checks_failed; then
        log_error "Pre-installation checks failed with critical errors!"
        log_error "Installation cannot proceed safely."
        
        log "=== SYSTEM INFORMATION FOR TROUBLESHOOTING ==="
        echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
        echo "Disk Space: $(df -h / | awk 'NR==2 {print $4}') available"
        echo "Graphics: $(lspci | grep -i vga | head -1)"
        echo "Current User: $(whoami)"
        echo "Target User: $USER_NAME"
        echo "TTY Mode: $RUNNING_IN_TTY"
        echo "Display: ${DISPLAY:-"Not set"}"
        
        perform_rollback "Pre-installation checks failed"
        return 1
    else
        log_success "All critical pre-installation checks passed!"
        
        if [[ ${#warnings[@]} -gt 0 ]]; then
            log_warning "There are ${#warnings[@]} warnings, but installation will proceed automatically."
        fi
        
        log_success "System is ready for ArchKit installation"
        return 0
    fi
}

# Update system
update_system() {
    log "Updating system packages..."
    sudo pacman -Syu --noconfirm && log_success "System updated successfully" || { log_error "Failed to update system"; exit 1; }
}

# Packages to install (incluye paquetes de VirtualBox para compatibilidad, sin Zsh)
packages=(lightdm lightdm-gtk-greeter bspwm sxhkd polybar dunst kitty fastfetch firefox feh fzf bashtop picom neovim xorg-server xorg-xinit xorg-xrandr xorg-xsetroot virtualbox-guest-utils xf86-video-vmware)

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
        show_progress $current $total "$package"
        sleep 0.5
    done

    echo ""
    
    # Display results
    if [ ${#failed_packages[@]} -eq 0 ]; then
        log_success "All packages installed successfully"
    else
        log_warning "Failed to install: ${failed_packages[*]}"
        log "Continuing with installation despite failed packages..."
    fi
}

# Function to enable and configure LightDM
setup_lightdm() {
    log "Configuring LightDM display manager for TTY installation..."
    
    # Verify LightDM is installed
    if ! verify_package_installed "lightdm"; then
        log_error "LightDM is not installed! Cannot configure display manager."
        return 1
    fi
    
    # Verify LightDM GTK greeter is installed
    if ! verify_package_installed "lightdm-gtk-greeter"; then
        log_error "LightDM GTK greeter is not installed! Cannot configure greeter."
        return 1
    fi
    
    # Stop any existing display manager
    local existing_dm=$(systemctl list-units --type=service --state=active | grep -E "(gdm|sddm|lightdm)" | awk '{print $1}' | head -1)
    if [[ -n "$existing_dm" ]]; then
        log_warning "Found active display manager: $existing_dm"
        sudo systemctl stop "$existing_dm"
        sudo systemctl disable "$existing_dm"
        log_success "Stopped and disabled $existing_dm"
    fi
    
    # Enable LightDM service
    if sudo systemctl enable lightdm.service; then
        log_success "LightDM service enabled"
    else
        log_error "Failed to enable LightDM service"
        return 1
    fi
    
    # Auto-configure VirtualBox service if detected
    if systemd-detect-virt -v | grep -q "oracle"; then
        log_success "AUTO: VirtualBox detectado - Configurando servicios automáticamente"
        if sudo systemctl enable vboxservice.service 2>/dev/null; then
            log_success "VirtualBox Guest Service habilitado automáticamente"
        fi
    fi
    
    # Configure LightDM
    local lightdm_conf="/etc/lightdm/lightdm.conf"
    if [[ -f "$lightdm_conf" ]]; then
        # Backup original config
        sudo cp "$lightdm_conf" "$lightdm_conf.backup.$(date +%Y%m%d_%H%M%S)"
        log_success "Backed up original LightDM configuration"
        
        # Configure greeter session
        sudo sed -i 's/#greeter-session=.*/greeter-session=lightdm-gtk-greeter/' "$lightdm_conf"
        
        # Configure user session for bspwm
        sudo sed -i 's/#user-session=.*/user-session=bspwm/' "$lightdm_conf"
        
        # TTY-specific configurations
        log "Applying TTY-optimized LightDM settings..."
        
        # Enable autologin for TTY installations (automático)
        log_success "AUTO: Configurando autologin para $USER_NAME automáticamente"
        sudo sed -i "s/#autologin-user=.*/autologin-user=$USER_NAME/" "$lightdm_conf"
        sudo sed -i 's/#autologin-user-timeout=.*/autologin-user-timeout=0/' "$lightdm_conf"
        log_success "Autologin configurado automáticamente para $USER_NAME"
        
        # Configure session timeout and other TTY-friendly settings
        sudo sed -i 's/#session-timeout=.*/session-timeout=60/' "$lightdm_conf"
        sudo sed -i 's/#greeter-hide-users=.*/greeter-hide-users=false/' "$lightdm_conf"
        
        log_success "LightDM configuration updated for TTY installation"
    else
        log_error "LightDM configuration file not found: $lightdm_conf"
        return 1
    fi
    
    # Create desktop session file for bspwm
    local session_file="/usr/share/xsessions/bspwm.desktop"
    if [[ ! -f "$session_file" ]]; then
        log "Creating bspwm desktop session file..."
        sudo tee "$session_file" > /dev/null << 'EOF'
[Desktop Entry]
Name=bspwm
Comment=Binary space partitioning window manager
Exec=bspwm
Type=Application
Keywords=wm;tiling
EOF
        log_success "Created bspwm desktop session file"
    else
        log_success "bspwm desktop session file already exists"
    fi
    
    # Create enhanced .xsession file optimized for TTY
    local xsession_file="/home/$USER_NAME/.xsession"
    if backup_file "$xsession_file"; then
        log "Creating TTY-optimized .xsession file..."
        cat > "$xsession_file" << EOF
#!/bin/bash
# TTY-optimized X session startup script
# Generated by ArchKit for user: $USER_NAME

# Set environment variables
export XDG_CURRENT_DESKTOP=bspwm
export XDG_SESSION_DESKTOP=bspwm
export XDG_SESSION_TYPE=x11
export XDG_CONFIG_HOME="\$HOME/.config"
export XDG_DATA_HOME="\$HOME/.local/share"
export XDG_CACHE_HOME="\$HOME/.cache"

# Set up PATH
export PATH="\$HOME/.local/bin:\$PATH"

# Log session start
echo "\$(date): Starting bspwm session for $USER_NAME" >> "\$HOME/.xsession.log"

# Wait for X server to be ready
sleep 2

# Start sxhkd (hotkey daemon) - critical for keyboard shortcuts
if command -v sxhkd >/dev/null 2>&1; then
    sxhkd &
    echo "\$(date): Started sxhkd" >> "\$HOME/.xsession.log"
else
    echo "\$(date): ERROR - sxhkd not found!" >> "\$HOME/.xsession.log"
fi

# Start polybar
if [[ -x "\$HOME/.config/polybar/launch.sh" ]]; then
    "\$HOME/.config/polybar/launch.sh" &
    echo "\$(date): Started polybar" >> "\$HOME/.xsession.log"
else
    echo "\$(date): WARNING - polybar launch script not found" >> "\$HOME/.xsession.log"
fi

# Start compositor
if command -v picom >/dev/null 2>&1; then
    picom &
    echo "\$(date): Started picom" >> "\$HOME/.xsession.log"
fi

# Start notification daemon
if command -v dunst >/dev/null 2>&1; then
    dunst &
    echo "\$(date): Started dunst" >> "\$HOME/.xsession.log"
fi

# Set wallpaper
if [[ -f "\$HOME/.config/wallpaper/onigirl.png" ]] && command -v feh >/dev/null 2>&1; then
    feh --bg-scale "\$HOME/.config/wallpaper/onigirl.png" &
    echo "\$(date): Set wallpaper" >> "\$HOME/.xsession.log"
fi

# Start bspwm (this should be the last command)
echo "\$(date): Starting bspwm window manager" >> "\$HOME/.xsession.log"
exec bspwm
EOF
        chmod +x "$xsession_file"
        chown "$USER_NAME:$USER_NAME" "$xsession_file"
        log_success "Created enhanced TTY-optimized .xsession file"
    fi
    
    # Create .xinitrc as backup method
    local xinitrc_file="/home/$USER_NAME/.xinitrc"
    if backup_file "$xinitrc_file"; then
        log "Creating .xinitrc backup file..."
        cat > "$xinitrc_file" << 'EOF'
#!/bin/bash
# Backup X initialization script
# This file is used when starting X manually with startx

# Source the main session file
if [[ -x "$HOME/.xsession" ]]; then
    exec "$HOME/.xsession"
else
    # Fallback minimal bspwm startup
    sxhkd &
    exec bspwm
fi
EOF
        chmod +x "$xinitrc_file"
        chown "$USER_NAME:$USER_NAME" "$xinitrc_file"
        log_success "Created .xinitrc backup file"
    fi
    
    # Verify LightDM configuration
    if sudo lightdm --test-mode --debug 2>/dev/null; then
        log_success "LightDM configuration test passed"
    else
        log_warning "LightDM configuration test failed - but continuing anyway"
    fi
    
    return 0
}

# Create configuration directories
create_directories() {
    log "Creating configuration directories..."
    local directories=(bspwm sxhkd polybar polybar/scripts picom dunst kitty wallpaper)
    
    # Ensure base config directory exists
    if [[ ! -d "$CONFIG_DIR" ]]; then
        log "Creating base configuration directory: $CONFIG_DIR"
        mkdir -p "$CONFIG_DIR"
        if [[ $? -ne 0 ]]; then
            log_error "Failed to create base configuration directory"
            return 1
        fi
    fi
    
    # Create subdirectories with verification
    for dir in "${directories[@]}"; do
        local full_path="$CONFIG_DIR/$dir"
        if [[ ! -d "$full_path" ]]; then
            log "Creating directory: $full_path"
            mkdir -p "$full_path"
            if [[ $? -ne 0 ]]; then
                log_error "Failed to create directory: $full_path"
                return 1
            fi
        else
            log "Directory already exists: $full_path"
        fi
        
        # Set proper ownership and permissions immediately (TTY optimized)
        chown -R "$USER_NAME:$USER_NAME" "$full_path" 2>/dev/null
        chmod -R 755 "$full_path" 2>/dev/null
        
        # Verify directory was created successfully
        if [[ -d "$full_path" && -w "$full_path" ]]; then
            log_success "✓ $dir"
        else
            log_error "✗ Failed to properly create $dir"
            return 1
        fi
    done
    
    log_success "All configuration directories created and verified"
    return 0
}

# Enhanced copy configurations with validation
copy_configurations() {
    log "Copying and validating configuration files..."
    
    # Verify source directory exists
    if [[ ! -d "$SCRIPT_DIR" ]]; then
        log_error "Script directory not found: $SCRIPT_DIR"
        return 1
    fi
    
    local config_mappings=(
        "bspwm:$CONFIG_DIR/bspwm"
        "sxhkd:$CONFIG_DIR/sxhkd"
        "polybar:$CONFIG_DIR/polybar"
        "kitty:$CONFIG_DIR/kitty"
        "wallpaper:$CONFIG_DIR/wallpaper"
    )
    
    local failed_copies=()
    
    for mapping in "${config_mappings[@]}"; do
        local source="${mapping%:*}"
        local dest="${mapping#*:}"
        local source_path="$SCRIPT_DIR/$source"
        
        log "Processing: $source → $dest"
        
        # Check if source exists
        if [[ ! -e "$source_path" ]]; then
            log_error "Source not found: $source_path"
            failed_copies+=("$source")
            continue
        fi
        
        # Create destination directory if needed
        local dest_dir=$(dirname "$dest")
        if [[ ! -d "$dest_dir" ]]; then
            mkdir -p "$dest_dir"
            chown -R "$USER_NAME:$USER_NAME" "$dest_dir"
        fi
        
        # Backup existing file/directory if it exists
        if backup_file "$dest"; then
            # Copy the configuration
            if [[ -d "$source_path" ]]; then
                # Copy directory contents
                cp -r "$source_path/." "$dest/"
                copy_result=$?
            else
                # Copy single file
                cp "$source_path" "$dest"
                copy_result=$?
            fi
            
            # Check if copy was successful
            if [[ $copy_result -eq 0 && -e "$dest" ]]; then
                # Set proper ownership and permissions (TTY optimized)
                chown -R "$USER_NAME:$USER_NAME" "$dest"
                
                # Set appropriate permissions based on file type
                if [[ -d "$dest" ]]; then
                    chmod -R 755 "$dest"
                else
                    chmod 644 "$dest"
                    # Make executable files executable
                    case "$dest" in
                        *bspwmrc|*launch.sh|*.sh) chmod +x "$dest" ;;
                    esac
                fi
                
                log_success "✓ Copied and configured: $source"
            else
                log_error "✗ Failed to copy: $source"
                failed_copies+=("$source")
            fi
        else
            log_warning "Skipped: $source (user choice)"
        fi
    done
    
    # Handle fonts installation with verification
    local fonts_dir="$SCRIPT_DIR/polybar/fonts"
    if [[ -d "$fonts_dir" ]]; then
        log "Installing fonts..."
        if sudo cp -r "$fonts_dir/." "/usr/share/fonts/" 2>/dev/null; then
            sudo fc-cache -fv &> /dev/null
            log_success "✓ Fonts installed and cache updated"
        else
            log_warning "Failed to install fonts - continuing anyway"
        fi
    else
        log_warning "Fonts directory not found: $fonts_dir"
    fi
    
    # Copy default system configs if they don't exist
    local system_configs=(
        "/etc/xdg/picom.conf:$CONFIG_DIR/picom/picom.conf"
        "/etc/dunst/dunstrc:$CONFIG_DIR/dunst/dunstrc"
    )
    
    for config_mapping in "${system_configs[@]}"; do
        local system_config="${config_mapping%:*}"
        local user_config="${config_mapping#*:}"
        
        if [[ ! -f "$user_config" && -f "$system_config" ]]; then
            log "Copying default system config: $(basename "$system_config")"
            cp "$system_config" "$user_config"
            chown "$USER_NAME:$USER_NAME" "$user_config"
            chmod 644 "$user_config"
            log_success "✓ Default $(basename "$system_config") copied"
        fi
    done
    
    # Report results
    if [ ${#failed_copies[@]} -eq 0 ]; then
        log_success "All configurations copied successfully"
        return 0
    else
        log_error "Failed to copy: ${failed_copies[*]}"
        log_warning "Some configurations may be missing - desktop environment may not work properly"
        return 1
    fi
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
    local executables=("$CONFIG_DIR/bspwm/bspwmrc" "$CONFIG_DIR/polybar/launch.sh" "$CONFIG_DIR/polybar/scripts/"*.sh)
    for file in "${executables[@]}"; do [[ -f "$file" ]] && chmod +x "$file"; done
    
    # Set ownership recursively
    chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME/.config" "/home/$USER_NAME/.local" 2>/dev/null
    
    log_success "Permissions and ownership configured"
}

# Main function with enhanced error handling and rollback support
main() {
    # Initialize logging
    log "Starting ArchKit - Enhanced BSPWM Installation Script"
    log "Version: 2.0 - TTY Optimized with Rollback Support"
    log "Timestamp: $(date)"
    echo ""
    
    # Trap errors for automatic rollback
    trap 'perform_rollback "Script interrupted or failed"' ERR EXIT
    
    # Phase 1: Environment Detection and Validation
    log "=== PHASE 1: ENVIRONMENT DETECTION ==="
    detect_environment
    check_root
    
    # Phase 2: Comprehensive Pre-Installation Checks
    log "=== PHASE 2: PRE-INSTALLATION VALIDATION ==="
    if ! run_pre_installation_checks; then
        log_error "Pre-installation checks failed. Installation aborted."
        exit 1
    fi
    
    # Phase 3: Internet and System Update
    log "=== PHASE 3: SYSTEM PREPARATION ==="
    if ! check_internet; then
        log_error "Internet connection required for installation"
        perform_rollback "No internet connection"
        exit 1
    fi
    
    log "Updating system packages..."
    if ! sudo pacman -Syu --noconfirm; then
        log_error "System update failed"
        perform_rollback "System update failed"
        exit 1
    fi
    log_success "System updated successfully"
    
    # Phase 4: Package Installation
    log "=== PHASE 4: PACKAGE INSTALLATION ==="
    if ! install_packages; then
        log_error "Package installation failed"
        perform_rollback "Package installation failed"
        exit 1
    fi
    
    # Phase 5: Service Configuration
    log "=== PHASE 5: SERVICE CONFIGURATION ==="
    if ! setup_lightdm; then
        log_error "LightDM setup failed"
        perform_rollback "LightDM setup failed"
        exit 1
    fi
    
    # Phase 6: Directory and Configuration Setup
    log "=== PHASE 6: CONFIGURATION SETUP ==="
    if ! create_directories; then
        log_error "Directory creation failed"
        perform_rollback "Directory creation failed"
        exit 1
    fi
    
    if ! copy_configurations; then
        log_error "Configuration copying failed"
        perform_rollback "Configuration copying failed"
        exit 1
    fi
    
    if ! set_permissions; then
        log_error "Permission setting failed"
        perform_rollback "Permission setting failed"
        exit 1
    fi
    
    # Phase 7: Shell Configuration (Skipped - Zsh removed for automation)
    log "=== PHASE 7: SHELL CONFIGURATION ==="
    log "Zsh configuration skipped for full automation"
    
    # Phase 8: Final Validation
    log "=== PHASE 8: FINAL VALIDATION ==="
    
    # Validate installation
    log "Validating installation..."
    
    # Check if all critical files exist
    local critical_files=(
        "/home/$USER_NAME/.config/bspwm/bspwmrc"
        "/home/$USER_NAME/.config/sxhkd/sxhkdrc"
        "/home/$USER_NAME/.config/polybar/config.ini"
        "/home/$USER_NAME/.xsession"
    )
    
    local validation_failed=false
    for file in "${critical_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Critical file missing: $file"
            validation_failed=true
        else
            log_success "Validated: $file"
        fi
    done
    
    # Check if services are properly configured
    if ! systemctl is-enabled lightdm >/dev/null 2>&1; then
        log_error "LightDM service is not enabled"
        validation_failed=true
    else
        log_success "LightDM service is enabled"
    fi
    
    # Check if bspwm and sxhkd are executable
    if ! sudo -u "$USER_NAME" which bspwm >/dev/null 2>&1; then
        log_error "bspwm is not accessible for user $USER_NAME"
        validation_failed=true
    else
        log_success "bspwm is accessible"
    fi
    
    if ! sudo -u "$USER_NAME" which sxhkd >/dev/null 2>&1; then
        log_error "sxhkd is not accessible for user $USER_NAME"
        validation_failed=true
    else
        log_success "sxhkd is accessible"
    fi
    
    if $validation_failed; then
        log_error "Final validation failed!"
        perform_rollback "Final validation failed"
        exit 1
    fi
    
    # Phase 9: Success and Cleanup
    log "=== PHASE 9: INSTALLATION COMPLETE ==="
    
    # Disable error trap since we succeeded
    trap - ERR EXIT
    
    # Clean up rollback files on success
    if [[ -f "/tmp/archkit_rollback_info" ]]; then
        source "/tmp/archkit_rollback_info"
        rm -rf "$ROLLBACK_DIR" 2>/dev/null || true
        rm -f "/tmp/archkit_rollback_info" 2>/dev/null || true
        log_success "Rollback files cleaned up automatically"
    fi
    
    # Display success message
    echo ""
    log_success "🎉 ArchKit installation completed successfully!"
    echo ""
    log "=== INSTALLATION SUMMARY ==="
    log "✅ BSPWM window manager installed and configured"
    log "✅ sxhkd hotkey daemon configured with essential shortcuts"
    log "✅ Polybar status bar installed with custom configuration"
    log "✅ LightDM display manager configured for automatic login"
    log "✅ Kitty terminal emulator installed"
    log "✅ Picom compositor for visual effects"
    log "✅ Dunst notification daemon"
    log "✅ Custom wallpaper and theme applied"
    log "✅ All configurations optimized for TTY installation"
    echo ""
    
    # Display essential shortcuts
    log "=== ESSENTIAL KEYBOARD SHORTCUTS ==="
    log "Super + Return        → Open terminal (Kitty)"
    log "Super + Space         → Application launcher (dmenu)"
    log "Super + Shift + q     → Close window"
    log "Super + Shift + r     → Restart BSPWM"
    log "Super + Shift + e     → Exit BSPWM"
    log "Super + {h,j,k,l}     → Focus window (left,down,up,right)"
    log "Super + Shift + {h,j,k,l} → Move window"
    log "Super + {1-9}         → Switch to desktop 1-9"
    log "Super + Shift + {1-9} → Move window to desktop 1-9"
    echo ""
    
    # Display next steps
    log "=== NEXT STEPS ==="
    if [[ "$RUNNING_IN_TTY" == "true" ]]; then
        log "1. Reboot your system: sudo reboot"
        log "2. After reboot, you should see the LightDM login screen"
        log "3. Log in with your user credentials"
        log "4. BSPWM should start automatically with Polybar and wallpaper"
        log "5. Press Super + Return to open a terminal and start using your system"
        echo ""
        log "If you encounter issues:"
        log "- Switch to TTY with Ctrl + Alt + F2"
        log "- Check logs: cat ~/.xsession.log"
        log "- Manual start: startx"
        echo ""
        
        log "Installation completed. System will reboot automatically in 10 seconds..."
        log "Press Ctrl+C to cancel automatic reboot if needed."
        sleep 10
        sudo reboot
    else
        log "1. Log out of your current session"
        log "2. Select 'bspwm' from the session menu in your display manager"
        log "3. Log in to start using BSPWM"
        echo ""
        log "Or restart LightDM: sudo systemctl restart lightdm"
    fi
    
    echo ""
    log_success "Thank you for using ArchKit! Enjoy your new BSPWM setup! 🚀"
}

# Run main function
main "$@"

