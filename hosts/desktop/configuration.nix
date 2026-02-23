{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix  # We will generate this on the desktop machine
    ./nvidia.nix
  ];

  # Identifies this machine for the Flake
  networking.hostName = "nixos-desktop";

  # Bootloader for a high-performance desktop
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable OpenRGB service for hardware control
  services.hardware.openrgb = {
    enable = true;
    motherboard="intel";
  };

  # Add OpenRGB to my desktop-specific packages
  environment.systemPackages = with pkgs; [
    openrgb
  ];

  # Ensure the i7-13700K has the latest patches for the 5070-Ti
  boot.kernelPackages = pkgs.linuxPackages;

  system.stateVersion = "25.11"; 
  nix.settings.max-jobs = 16;
  nix.settings.cores = 0;  # Use all available cores for building

  security.sudo.extraConfig = ''
    Defaults env_reset,timestamp_timeout=240
  ''; 
}
