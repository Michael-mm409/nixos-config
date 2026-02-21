#!/usr/bin/env bash
set -e
SCRIPTPATH="/etc/nixos"
cd "$SCRIPTPATH"

# 1. Capture changes
changes=$(git status --porcelain | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//')

# 2. Stage and Build
git add .
echo "Building NixOS for $(hostname)..."
sudo nixos-rebuild switch --flake .

# 3. THE FIX: Wait a moment for the system to register the new generation
sleep 1 

# 4. Get the NEWEST generation number
# This looks at the system profile which is what the bootloader uses
gen=$(sudo nix-env -p /nix/var/nix/profiles/system --list-generations | tail -n 1 | awk '{print $1}')
host=$(hostname)

# 5. Commit with the accurate Gen number
if [ -z "$changes" ]; then
    msg="$host: Refresh Gen $gen"
else
    msg="$host: Update Gen $gen | Modified: $changes"
fi

git commit -m "$msg"
git push origin main
echo "Done! Generation $gen is now officially live on GitHub."
