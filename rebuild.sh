#!/usr/bin/env bash
set -e
cd /etc/nixos

# 1. Capture names of modified files BEFORE staging them
changes=$(git status --porcelain | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//')

# 2. Stage all changes
git add .

# 3. Build and Switch
echo "Building NixOS for $(hostname)..."
sudo nixos-rebuild switch --flake .

# 4. Get metadata for the commit
gen=$(sudo nixos-rebuild list-generations | grep current | awk '{print $1}')
host=$(hostname)

# 4.1 Capture the names of modified files
# We use sed to trim the trailing space
changes=$(git status --porcelain | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//')

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
