#!/usr/bin/env bash
# /etc/nixos/rebuild.sh

set -e # Exit immediately if a command fails

# 1. Navigate to config directory
cd /etc/nixos

# 2. Stage all changes (required for Flakes to see new files)
sudo git add .

# 3. Run the rebuild
# It uses your current hostname to automatically select the right Flake output
echo "Building NixOS..."
sudo nixos-rebuild switch --flake .

# 4. If we reach here, the build succeeded! 
# Get the new generation number for the commit message
gen=$(nixos-rebuild list-generations | grep current | awk '{print $1}')

# 5. Commit with a helpful message
sudo git commit -m "NixOS Update: Generation $gen ($(date +'%Y-%m-%d %H:%M'))"

echo "Done! Configuration built and committed as Generation $gen."
