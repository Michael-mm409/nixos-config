{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix  # We will generate this on the desktop machine
  ];

  # Identifies this machine for the Flake
  networking.hostName = "nixos-desktop";

  # Bootloader for a high-performance desktop
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Ensure the i7-13700K has the latest patches for the 5070-Ti
  boot.kernelPackages = pkgs.linuxPackages;

  system.stateVersion = "25.11"; 
  nix.settings.max-jobs = 16;
  nix.settings.cores = 0;  # Use all available cores for building
}
