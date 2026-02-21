#!/usr/bin/env bash
set -e
cd /etc/nixos

# 1. Stage all changes
git add .

# 2. Build and Switch
echo "Building NixOS for $(hostname)..."
sudo nixos-rebuild switch --flake .

# 3. Get metadata for the commit
gen=$(sudo nixos-rebuild list-generations | grep current | awk '{print $1}')
host=$(hostname)
# This captures the names of any files you modified
changes=$(git status --porcelain | awk '{print $2}' | tr '\n' ' ')

# 4. Commit with detailed info
git commit -m "$host Update: Gen $gen | Files: $changes"

# 5. Push to GitHub
echo "Syncing with GitHub..."
git push origin main

echo "Done! Generation $gen is live on GitHub."
