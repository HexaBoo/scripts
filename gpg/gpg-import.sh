#!/bin/bash

echo "=========================================="
echo "🔐 GPG Key Import Script (Private & Public)"
echo "=========================================="

# Check for GPG
if ! command -v gpg &> /dev/null; then
    echo "❌ GPG is not installed. Please install it first."
    exit 1
fi

# Ask for directory containing key files
read -p "Enter path to directory containing .asc key files: " KEY_DIR

if [ ! -d "$KEY_DIR" ]; then
    echo "❌ Directory '$KEY_DIR' does not exist."
    exit 1
fi

# Import all .asc files
FOUND_KEYS=0
for file in "$KEY_DIR"/*.asc; do
    if [ -f "$file" ]; then
        echo "🔐 Importing key file: $file"
        gpg --import "$file"
        FOUND_KEYS=$((FOUND_KEYS + 1))
    fi
done

if [ "$FOUND_KEYS" -eq 0 ]; then
    echo "⚠️ No .asc files found in $KEY_DIR"
    exit 1
fi

# Show imported secret keys
echo ""
echo "✅ GPG Keys Imported. Current secret keys:"
gpg --list-secret-keys --keyid-format=long

# Suggest Git setup
echo ""
echo "👉 You can now set up Git to use your GPG key:"
echo "  git config --global user.signingkey YOUR_KEY_ID"
echo "  git config --global commit.gpgsign true"

# Optional GPG_TTY setup
if ! grep -q "GPG_TTY" ~/.bashrc; then
    echo 'export GPG_TTY=$(tty)' >> ~/.bashrc
    echo "🛠 Added 'export GPG_TTY=\$(tty)' to ~/.bashrc"
fi
