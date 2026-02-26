#!/usr/bin/env bash
set -e
pushd ~/nixos-config

# 1. Capture changes before adding them
changes=$(git status --porcelain | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//')

# 2. Stage and Build
git add .
host=$(hostname)
echo "Building NixOS for $host..."

# THE FIX: Target the specific host and use 'boot' if storage/hardware changed
# This avoids the 'home.mount' busy error on the desktop
if [ "$host" = "nixos-laptop" ]; then
	echo "Laptop detected. Using 'boot' to prevent session logout..."
	sudo nixos-rebuild boot --flake .#$host
else
	if git diff --cached --name-only | grep -E "storage.nix|hardware-configuration.nix"; then
    		echo "⚠️  Storage changes detected. Using 'boot' mode..."
    		sudo nixos-rebuild boot --flake .#$host
	else
		sudo nixos-rebuild switch --flake .#$host
	fi
fi

# 3. Wait a moment for the system to register the new generation
sleep 1 

# 4. Get the NEWEST generation number
gen=$(sudo nix-env -p /nix/var/nix/profiles/system --list-generations | tail -n 1 | awk '{print $1}')

# 5. Commit with the accurate Gen number
if [ -z "$changes" ]; then
    msg="$host: Refresh Gen $gen"
else
    msg="$host: Update Gen $gen | Modified: $changes"
fi

git commit -m "$msg"
git push origin main
echo "Done! Generation $gen is now officially live on GitHub."

popd
