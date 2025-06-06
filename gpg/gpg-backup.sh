#!/bin/bash

read -p "Enter your GPG Key ID: " KEY_ID

# Output directory
mkdir -p gpg-backup

# Export keys
gpg --export --armor "$KEY_ID" > gpg-backup/public-key.asc
gpg --export-secret-keys --armor "$KEY_ID" > gpg-backup/private-key.asc

echo "✅ Keys exported to ./gpg-backup/"
ls -l gpg-backup/
