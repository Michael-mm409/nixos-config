#!/bin/bash
# setup-fedora.sh - Universal Setup for Michael's Devices

HOSTNAME=$(hostname)
echo "🚀 Starting Michael's Fedora Setup on $HOSTNAME..."

# 1. Update Fedora and install system essentials
sudo dnf update -y
sudo dnf install -y curl git wget util-linux-user dnf-plugins-core

# 2. Hardware Specific Installs (Nvidia/OpenRGB for Desktop, Powertop for Laptop)
if [[ "$HOSTNAME" == "nixos-desktop" || "$HOSTNAME" == "michael-desktop" ]]; then
    echo "🖥️  Desktop Detected: Installing Nvidia Drivers and OpenRGB..."
    # Add RPM Fusion for the best Nvidia experience on Fedora
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda openrgb
elif [[ "$HOSTNAME" == "michael-laptop" ]]; then
    echo "💻 Laptop Detected: Installing Power Management..."
    sudo dnf install -y powertop
fi

# 3. Install Tailscale (Native)
sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf install -y tailscale
sudo systemctl enable --now tailscaled
echo "✅ Tailscale installed."

# 4. Install the Latest Miniconda
echo "🐍 Fetching latest Miniconda..."
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
bash miniconda.sh -b -p $HOME/miniconda
rm miniconda.sh
$HOME/miniconda/bin/conda init bash

# 5. Install Nix
if ! command -v nix &> /dev/null; then
    echo "❄️  Installing Nix..."
    curl -L https://nixos.org/nix/install | sh --daemon
    source /etc/profile.d/nix.sh
fi

# 6. Apply Home Manager using the specific Hostname
echo "🏠 Applying Home Manager for $HOSTNAME..."
nix run home-manager/master -- init --switch ~/nixos-config#$HOSTNAME

echo "🎉 Setup Complete! Please RESTART your terminal."
