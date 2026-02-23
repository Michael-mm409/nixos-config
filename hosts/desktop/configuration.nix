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
    package = pkgs.openrgb-with-all-plugins;
  };

  # Add OpenRGB to my desktop-specific packages
  environment.systemPackages = with pkgs; [
    openrgb-with-all-plugins
    psmisc  # This provides the 'fuser' and 'pstree' commands
    desktop-file-utils # This provides update-desktop-database
  ];

  system.activationScripts.openrgb-plugins = {
    text = ''
      mkdir -p /home/michael/.config/OpenRGB/plugins
      chown michael:users /home/michael/.config/OpenRGB/plugins
    '';
  };
  
  # System-level RGB control for Boot and Shutdown
  systemd.services.openrgb-automator = {
    description = "Sync OpenRGB profiles on Boot and Shutdown";
    after = [ "network.target" "multi-user.target" ];
    wantedBy = [ "multi-user.target" "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Apply Bright on Startup
      ExecStart = "${pkgs.openrgb-with-all-plugins}/bin/openrgb --profile Bright.orp";
      # Apply Dark on Shutdown/Suspend
      ExecStop = "${pkgs.openrgb-with-all-plugins}/bin/openrgb --profile Dark.orp";
    };
  };

  # Ensure the i7-13700K has the latest patches for the 5070-Ti
  boot.kernelPackages = pkgs.linuxPackages;

  system.stateVersion = "25.11"; 
  nix.settings.max-jobs = 16;
  nix.settings.cores = 0;  # Use all available cores for building

  security.sudo.extraConfig = ''
    Defaults env_reset,timestamp_timeout=240
  ''; 
}
