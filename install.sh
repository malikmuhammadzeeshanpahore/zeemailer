#!/bin/bash

echo "==================================="
echo " Installing ZeeMailer for Linux... "
echo "==================================="

# Check for Node.js
if ! command -v node &> /dev/null
then
    echo "Node.js could not be found."
    echo "Please install Node.js from https://nodejs.org/ and try again."
    exit 1
fi

echo "Node.js found: $(node -v)"

# Install Dependencies
echo "Installing dependencies..."
npm install

APP_DIR=$(pwd)
DESKTOP_DIR="$HOME/Desktop"
if [ ! -d "$DESKTOP_DIR" ]; then
    DESKTOP_DIR="$HOME"
fi

# Create a shell script wrapper
echo "Creating global alias 'zeemailer'..."
mkdir -p ~/.local/bin

cat <<EOF > ~/.local/bin/zeemailer
#!/bin/bash
# Check if desktop icon exists, if not recreate it
if [ ! -f "$DESKTOP_DIR/ZeeMailer.desktop" ]; then
    echo "Restoring Desktop Shortcut..."
    cat <<INNEREOF > "$DESKTOP_DIR/ZeeMailer.desktop"
[Desktop Entry]
Version=1.0
Name=ZeeMailer
Comment=AI-Assisted Email Marketing Tool
Exec=$HOME/.local/bin/zeemailer
Icon=$APP_DIR/assets/logo.png
Terminal=true
Type=Application
Categories=Utility;
INNEREOF
    chmod +x "$DESKTOP_DIR/ZeeMailer.desktop"
fi

cd "$APP_DIR"
node server.js
EOF

chmod +x ~/.local/bin/zeemailer

# Add to PATH temporarily if not already
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "Note: Make sure ~/.local/bin is in your PATH."
fi

# Create Desktop Shortcut Initially
cat <<EOF > "$DESKTOP_DIR/ZeeMailer.desktop"
[Desktop Entry]
Version=1.0
Name=ZeeMailer
Comment=AI-Assisted Email Marketing Tool
Exec=$HOME/.local/bin/zeemailer
Icon=$APP_DIR/assets/logo.png
Terminal=true
Type=Application
Categories=Utility;
EOF

chmod +x "$DESKTOP_DIR/ZeeMailer.desktop"

echo "==================================="
echo " Installation Complete!"
echo " You can now double-click 'ZeeMailer' on your Desktop"
echo " Or run 'zeemailer' from your terminal."
echo "==================================="
