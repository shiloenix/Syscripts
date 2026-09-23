#!/usr/bin/env bash
# Complete installer: Clones → Builds → Installs to /usr/local or /opt
# Works on Arch Linux

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Complete Package Installer (Build from Source) ===${NC}"
echo "This will clone, compile, and install applications system-wide."
echo "Build times: Flutter (fast), Waterfox (30-60 min), Brave (45-90 min)"
echo ""

# Ensure base-devel exists
if ! pacman -Q base-devel &>/dev/null; then
    echo -e "${YELLOW}Installing base-devel...${NC}"
    sudo pacman -S --needed base-devel git wget
fi

# Function to create .desktop file
create_desktop_entry() {
    local name="$1"
    local exec_path="$2"
    local icon_path="$3"
    local comment="$4"
    
    cat <<EOF | sudo tee "/usr/share/applications/${name}.desktop" > /dev/null
[Desktop Entry]
Name=${name^}
Comment=${comment}
Exec=${exec_path}
Icon=${icon_path}
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF
    echo -e "${GREEN}Created desktop entry: ${name}.desktop${NC}"
}

# Function to add to PATH
add_to_path() {
    local bin_path="$1"
    if ! grep -q "$bin_path" ~/.bashrc; then
        echo "export PATH=\"\$PATH:$bin_path\"" >> ~/.bashrc
        echo -e "${YELLOW}Added $bin_path to PATH in ~/.bashrc${NC}"
    fi
    export PATH="$PATH:$bin_path"
}

install_flutter() {
    echo -e "${BLUE}=== Installing Flutter (Stable) ===${NC}"
    
    # Clone if not exists
    if [ ! -d "/opt/flutter" ]; then
        sudo git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
        sudo chown -R $USER:$USER /opt/flutter
    else
        echo "Updating Flutter..."
        cd /opt/flutter && git pull origin stable
    fi
    
    # Add to PATH
    add_to_path "/opt/flutter/bin"
    
    # Precache and verify
    echo "Running flutter precache..."
    /opt/flutter/bin/flutter precache
    
    echo -e "${GREEN}✓ Flutter installed!${NC}"
    echo "Run 'flutter doctor' to verify."
    echo "To update later: cd /opt/flutter && git pull"
}

install_waterfox() {
    echo -e "${BLUE}=== Installing Waterfox (Stable) ===${NC}"
    echo -e "${YELLOW}This will take 30-60 minutes to compile...${NC}"
    
    # Install dependencies
    sudo pacman -S --needed --noconfirm base-devel git python2 yasm libpulse \
        alsa-lib gtk2 gtk3 libxt mime-types dbus-glib ffmpeg nss nspr \
        libevent sqlite ttf-font freetype2 icu libvpx libjpeg zlib
    
    # Clone
    if [ ! -d "/opt/waterfox" ]; then
        sudo git clone https://github.com/WaterfoxCo/Waterfox.git -b stable /opt/waterfox
        sudo chown -R $USER:$USER /opt/waterfox
    else
        cd /opt/waterfox && git pull origin stable
    fi
    
    cd /opt/waterfox
    
    # Build
    echo "Building Waterfox (this is the long part)..."
    ./mach build
    
    # Install to /usr/local (system-wide)
    echo "Installing to /usr/local..."
    sudo ./mach install
    
    # Create desktop entry
    create_desktop_entry "waterfox" "/usr/local/bin/waterfox" "waterfox" "Waterfox Web Browser"
    
    echo -e "${GREEN}✓ Waterfox installed!${NC}"
    echo "Run with: waterfox"
    echo "To update: cd /opt/waterfox && git pull && ./mach build && sudo ./mach install"
}

install_brave() {
    echo -e "${BLUE}=== Installing Brave Browser (Stable) ===${NC}"
    echo -e "${YELLOW}This will take 45-90 minutes to compile...${NC}"
    
    # Install dependencies (Node.js 18+ required)
    sudo pacman -S --needed --noconfirm git npm python2 python gcc make
    
    # Clone
    if [ ! -d "/opt/brave-browser" ]; then
        sudo git clone https://github.com/brave/brave-browser.git /opt/brave-browser
        sudo chown -R $USER:$USER /opt/brave-browser
    else
        cd /opt/brave-browser && git pull
    fi
    
    cd /opt/brave-browser
    
    # Install npm dependencies
    npm install
    
    # Build (this creates the browser binary)
    echo "Building Brave (very long process)..."
    npm run build
    
    # Install to /usr/local
    echo "Installing to /usr/local..."
    sudo npm run install --prefix=/usr/local 2>/dev/null || {
        # Fallback: copy built files manually
        sudo mkdir -p /usr/local/share/brave
        sudo cp -r src/out/Release/* /usr/local/share/brave/ 2>/dev/null || true
        sudo ln -sf /usr/local/share/brave/brave /usr/local/bin/brave 2>/dev/null || true
    }
    
    create_desktop_entry "brave" "/usr/local/bin/brave" "brave" "Brave Web Browser"
    
    echo -e "${GREEN}✓ Brave installed!${NC}"
    echo "Run with: brave"
    echo "To update: cd /opt/brave-browser && git pull && npm install && npm run build"
}

# Menu
while true; do
    echo ""
    echo "Select package to install:"
    echo "1) Flutter (SDK - ready to use immediately)"
    echo "2) Waterfox (Browser - requires 30-60 min compile)"
    echo "3) Brave (Browser - requires 45-90 min compile)"
    echo "4) Install All"
    echo "5) Update All (git pull + rebuild)"
    echo "0) Exit"
    read -p "Choice: " choice
    
    case $choice in
        1) install_flutter ;;
        2) install_waterfox ;;
        3) install_brave ;;
        4) 
            install_flutter
            install_waterfox  
            install_brave
            ;;
        5)
            echo "Updating all packages..."
            [ -d "/opt/flutter" ] && cd /opt/flutter && git pull && echo "Flutter updated"
            [ -d "/opt/waterfox" ] && cd /opt/waterfox && git pull && ./mach build && sudo ./mach install && echo "Waterfox updated"
            [ -d "/opt/brave-browser" ] && cd /opt/brave-browser && git pull && npm install && npm run build && echo "Brave updated"
            ;;
        0) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
done
