#!/bin/bash
# setup-fedora.sh - Michael's Automated Fedora Environment

echo "🚀 Starting Michael's Fedora Setup..."

# 1. Update Fedora and install system essentials
sudo dnf update -y
sudo dnf install -y curl git wget util-linux-user # util-linux-user for chsh

# 2. Install Tailscale (Native Fedora way for stability)
sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf install -y tailscale
sudo systemctl enable --now tailscaled
echo "✅ Tailscale installed. Run 'sudo tailscale up' later to log in."

# 3. Install the Latest Miniconda
echo "🐍 Fetching latest Miniconda..."
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
bash miniconda.sh -b -p $HOME/miniconda
rm miniconda.sh
# Initialize for bash
$HOME/miniconda/bin/conda init bash
echo "✅ Miniconda installed to ~/miniconda"

# 4. Install Nix (Multi-user daemon)
if ! command -v nix &> /dev/null; then
    echo "❄️ Installing Nix..."
    curl -L https://nixos.org/nix/install | sh --daemon
    source /etc/profile.d/nix.sh
else
    echo "✅ Nix already installed."
fi

# 5. Apply Michael's Home Manager Config
echo "🏠 Applying Home Manager (Michael-Layer)..."
nix run home-manager/master -- init --switch ~/nixos-config#michael-laptop

echo "🎉 Setup Complete! Please RESTART your terminal."
