#!/bin/bash

echo "=========================================="
echo "🔐 GPG Key Import Script (Private & Public)"
echo "=========================================="

# Check if gpg is installed
if ! command -v gpg &> /dev/null; then
    echo "❌ GPG is not installed. Please install it first."
    exit 1
fi

# Prompt user for directory containing key files
read -rp "Enter the directory path containing .asc key files: " KEY_DIR

# Validate directory exists
if [[ ! -d "$KEY_DIR" ]]; then
    echo "❌ Directory '$KEY_DIR' does not exist."
    exit 1
fi

# Import all .asc files in the directory
FOUND_KEYS=0
for keyfile in "$KEY_DIR"/*.asc; do
    if [[ -f "$keyfile" ]]; then
        echo "🔐 Importing key file: $keyfile"
        gpg --import "$keyfile"
        ((FOUND_KEYS++))
    fi
done

if [[ $FOUND_KEYS -eq 0 ]]; then
    echo "⚠️ No .asc key files found in '$KEY_DIR'. Nothing imported."
    exit 1
fi

# Show the imported secret keys summary
echo ""
echo "✅ GPG keys imported successfully. Your secret keys:"
gpg --list-secret-keys --keyid-format=long

# Detect newest imported GPG key ID (long format)
# We'll get the most recent secret key's KEY_ID (16 hex digits)
NEW_KEY_ID=$(gpg --list-secret-keys --keyid-format=long --with-colons | \
    grep '^sec' | head -n1 | cut -d':' -f5)

if [[ -z "$NEW_KEY_ID" ]]; then
    echo "❌ Failed to detect your GPG key ID."
    exit 1
fi

# Configure Git to use this GPG key for signing commits
git config --global user.signingkey "$NEW_KEY_ID"
git config --global commit.gpgsign true

echo ""
echo "👉 Git has been configured to sign commits with your GPG key:"
echo "   user.signingkey = $NEW_KEY_ID"
echo "   commit.gpgsign = true"

# Add GPG_TTY to ~/.bashrc if not already present
if ! grep -q "GPG_TTY" ~/.bashrc 2>/dev/null; then
    echo 'export GPG_TTY=$(tty)' >> ~/.bashrc
    echo "🛠 Added 'export GPG_TTY=\$(tty)' to ~/.bashrc for proper GPG interaction."
fi

echo "Done!"
