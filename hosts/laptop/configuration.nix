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

  swapDevices = [ {
    device = "/dev/disk/by-uuid/5337e082-7a71-46c0-97dd-88853aa6ef3a";
  } ];
}
