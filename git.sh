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

echo "==============================="
echo "🔧 Setting up Git Aliases"
echo "==============================="

# Define aliases
declare -A aliases=(
    [c]="commit -s"
    [cam]="commit --am"
    [cm]="commit"
    [csm]="commit -s -m"
    [ca]="cherry-pick --abort"
    [cr]="cherry-pick --signoff"
    [p]="push -f"
    [cc]="cherry-pick --continue"
    [cs]="cherry-pick --skip"
    [cp]="cherry-pick"
    [r]="revert"
    [rc]="revert --continue"
    [ro]="remote rm origin"
    [ra]="remote add origin"
    [s]="switch -c"
    [b]="branch"
    [rh]="reset --hard"
    [ch]="checkout"
    [f]="fetch"
    [m]="merge"
)

# Apply aliases to Git config
for key in "${!aliases[@]}"; do
    value="${aliases[$key]}"
    git config --global alias."$key" "$value"
    echo "✅ alias.$key = $value"
done

echo ""
echo "🎉 All Git aliases have been configured successfully."

HOOKS_DIR="$HOME/.githooks"

mkdir -p "$HOOKS_DIR"
curl -Lo "$HOOKS_DIR/commit-msg" https://gerrit-review.googlesource.com/tools/hooks/commit-msg
chmod +x "$HOOKS_DIR/commit-msg"

git config --global core.hooksPath "$HOOKS_DIR"

echo "✅ Gerrit Change-Id commit-msg hook installed globally."
echo "Done ✓"
