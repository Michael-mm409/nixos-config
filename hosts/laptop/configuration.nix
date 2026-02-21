{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
  ];

  # Machine-specific settings
  networking.hostName = "nixos-laptop";
  networking.networkmanager.enable = true;

  # Bootloader and Kernel
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest; # Perfect for 13th-gen Intel

  system.stateVersion = "25.11"; 
}
