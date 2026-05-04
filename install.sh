#!/bin/bash

echo "==================================="
echo "  ZeeMailer Installer - Linux      "
echo "==================================="

APP_DIR=$(pwd)
DESKTOP_DIR="$HOME/Desktop"
if [ ! -d "$DESKTOP_DIR" ]; then
    DESKTOP_DIR="$HOME"
fi

# ─── Step 1: Check / Install Node.js ─────────────────────────────────────────
NODE_MIN_VERSION=18

check_node() {
    if command -v node &>/dev/null; then
        NODE_VER=$(node -e "console.log(process.versions.node.split('.')[0])" 2>/dev/null)
        if [ "$NODE_VER" -ge "$NODE_MIN_VERSION" ] 2>/dev/null; then
            echo "✅ Node.js $(node -v) is already installed."
            return 0
        else
            echo "⚠️  Node.js $(node -v) is too old. Minimum required: v${NODE_MIN_VERSION}."
            return 1
        fi
    fi
    return 1
}

install_node_nvm() {
    echo "🔧 Installing Node.js via NVM..."
    export NVM_DIR="$HOME/.nvm"
    if [ ! -f "$NVM_DIR/nvm.sh" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    # Load nvm in current shell
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    nvm alias default node
}

install_node_pkg() {
    echo "🔧 Trying system package manager..."
    if command -v apt &>/dev/null; then
        echo "Detected apt (Debian/Ubuntu)..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif command -v dnf &>/dev/null; then
        echo "Detected dnf (Fedora/RHEL)..."
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
        sudo dnf install -y nodejs
    elif command -v yum &>/dev/null; then
        echo "Detected yum (CentOS/RHEL)..."
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
        sudo yum install -y nodejs
    elif command -v pacman &>/dev/null; then
        echo "Detected pacman (Arch Linux)..."
        sudo pacman -Sy --noconfirm nodejs npm
    elif command -v zypper &>/dev/null; then
        echo "Detected zypper (openSUSE)..."
        sudo zypper install -y nodejs npm
    else
        return 1
    fi
    return 0
}

if ! check_node; then
    echo ""
    echo "📦 Node.js not found or too old. Installing Node.js LTS..."
    
    # Try NVM first (works without sudo)
    if command -v curl &>/dev/null; then
        install_node_nvm
        # Reload nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi

    # Check again, if nvm failed, try system pkg
    if ! check_node; then
        if ! install_node_pkg; then
            echo "❌ Could not install Node.js automatically."
            echo "   Please install it manually from: https://nodejs.org/en/download/"
            exit 1
        fi
    fi

    # Final check
    if ! check_node; then
        echo "❌ Node.js installation failed. Please install manually: https://nodejs.org/"
        exit 1
    fi
fi

echo ""

# ─── Step 2: Install npm dependencies ────────────────────────────────────────
echo "📦 Installing dependencies..."
npm install --omit=dev
echo "✅ Dependencies installed."
echo ""

# ─── Step 3: Create global 'zeemailer' launcher ───────────────────────────────
echo "🔗 Creating 'zeemailer' terminal command..."
mkdir -p "$HOME/.local/bin"

# Load nvm in wrapper if needed
NVM_LOADER=""
if [ -f "$HOME/.nvm/nvm.sh" ]; then
    NVM_LOADER='export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
fi

cat > "$HOME/.local/bin/zeemailer" <<WRAPPER
#!/bin/bash
${NVM_LOADER}

# Restore desktop icon if missing
if [ ! -f "${DESKTOP_DIR}/ZeeMailer.desktop" ]; then
    echo "🔄 Restoring desktop shortcut..."
    cat > "${DESKTOP_DIR}/ZeeMailer.desktop" <<DESKEOF
[Desktop Entry]
Version=1.0
Name=ZeeMailer
Comment=AI-Assisted Email Marketing Tool
Exec=${HOME}/.local/bin/zeemailer
Icon=${APP_DIR}/assets/logo.png
Terminal=true
Type=Application
Categories=Utility;
DESKEOF
    chmod +x "${DESKTOP_DIR}/ZeeMailer.desktop"
fi

cd "${APP_DIR}"
node server.js
WRAPPER

chmod +x "$HOME/.local/bin/zeemailer"
echo "✅ 'zeemailer' command created."

# ─── Step 4: Add ~/.local/bin to PATH if missing ─────────────────────────────
SHELL_RC="$HOME/.bashrc"
[ -n "$ZSH_VERSION" ] && SHELL_RC="$HOME/.zshrc"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    echo "🔧 Adding ~/.local/bin to PATH in ${SHELL_RC}..."
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    export PATH="$HOME/.local/bin:$PATH"
    echo "✅ PATH updated. Restart your terminal or run: source ${SHELL_RC}"
fi

# ─── Step 5: Create Desktop Shortcut ─────────────────────────────────────────
echo ""
echo "🖥️  Creating desktop shortcut..."
cat > "${DESKTOP_DIR}/ZeeMailer.desktop" <<DESKTOP
[Desktop Entry]
Version=1.0
Name=ZeeMailer
Comment=AI-Assisted Email Marketing Tool
Exec=${HOME}/.local/bin/zeemailer
Icon=${APP_DIR}/assets/logo.png
Terminal=true
Type=Application
Categories=Utility;
DESKTOP

chmod +x "${DESKTOP_DIR}/ZeeMailer.desktop"
echo "✅ Desktop shortcut created."

echo ""
echo "==================================="
echo "  ✅ Installation Complete!        "
echo "                                   "
echo "  Launch options:                  "
echo "  • Double-click 'ZeeMailer'       "
echo "    on your Desktop                "
echo "  • Or type: zeemailer             "
echo "    in a new terminal              "
echo "==================================="
