#!/bin/bash

echo "=============================================="
echo " Git Identity & Credential Setup with GitHub CLI"
echo "=============================================="
echo ""

# Check for required tools
for cmd in git gh jq; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ Required command '$cmd' is not installed."
        if [[ $cmd == "gh" ]]; then
            echo "Install gh: https://cli.github.com/"
        elif [[ $cmd == "jq" ]]; then
            echo "Install jq (Linux): sudo apt install jq"
        fi
        exit 1
    fi
done

# GitHub CLI Authentication
echo "🔐 Logging into GitHub..."
gh auth login
if [ $? -ne 0 ]; then
    echo "❌ GitHub authentication failed. Exiting."
    exit 1
fi

# Fetch GitHub username and email
echo "📦 Fetching GitHub user info..."
GH_USER_JSON=$(gh api user)
GH_USERNAME=$(echo "$GH_USER_JSON" | jq -r '.login')
GH_EMAIL=$(echo "$GH_USER_JSON" | jq -r '.email')

# If email is unavailable, prompt the user
if [ "$GH_EMAIL" == "null" ] || [ -z "$GH_EMAIL" ]; then
    echo "⚠️  GitHub email not publicly available."
    read -p "Enter the email you want to use for Git: " GH_EMAIL
fi

# Confirm Git identity
echo ""
echo "Git will be configured with the following identity:"
echo "Username: $GH_USERNAME"
echo "Email: $GH_EMAIL"
read -p "Continue? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "❌ Aborted by user."
    exit 1
fi

# Set Git identity
git config --global user.name "$GH_USERNAME"
git config --global user.email "$GH_EMAIL"
echo "✅ Git user identity set."

# Choose credential helper
echo ""
echo "Which Git credential helper do you want to use?"
echo "1) GitHub CLI (recommended)"
echo "2) Git Credential Manager (manager-core)"
read -p "Choose [1/2]: " HELPER_CHOICE

if [[ "$HELPER_CHOICE" == "2" ]]; then
    git config --global credential.helper manager-core
    echo "✅ Git is now using: manager-core"
else
    git config --global credential.helper '!gh auth git-credential'
    echo "✅ Git is now using: GitHub CLI as credential helper"
fi

# Display final config
echo ""
echo "🎉 Setup complete!"
echo "Git identity:"
git config --global user.name
git config --global user.email
echo "Credential helper:"
git config --global credential.helper

echo ""
echo "Test it with:"
echo "  git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git"

