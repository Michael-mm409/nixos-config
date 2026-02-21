#!/usr/bin/env bash
set -e

SCRIPTPATH="/etc/nixos"
cd "$SCRIPTPATH"

# 1. Capture names of modified files BEFORE staging them
changes=$(git status --porcelain | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//')

# 2. Stage all changes
git add .

# 3. Build and Switch
echo "Building NixOS for $(hostname)..."
sudo nixos-rebuild switch --flake .

# 4. Get metadata for the commit
# This version works better because it doesn't rely on the word "current"
gen=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -n 1 | awk '{print $1}')
host=$(hostname)

# 5. Detailed commit logic
# Corrected the quotes here: "$changes"
if [ -z "$changes" ]; then
    msg="$host: Refresh Gen $gen"
else
    # Added $gen back into this message string
    msg="$host: Update Gen $gen | Modified: $changes"
fi

git commit -m "$msg"

# 6. Push to GitHub
echo "Syncing with GitHub..."
git push origin main

echo "Done! Generation $gen is live on GitHub."
