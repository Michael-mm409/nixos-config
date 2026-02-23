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
  systemd.services.openrgb-system-sync = {
    description = "OpenRGB System-Wide Sync (Bright on Boot, Dark on Shutdown)";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Load the Bright profile as soon as the system reaches multi-user state
      ExecStart = "${pkgs.openrgb-with-all-plugins}/bin/openrgb --profile /home/michael/.config/OpenRGB/Bright.orp";
      # Load the Dark profile during shutdown, suspend, or restart
      ExecStop = "${pkgs.openrgb-with-all-plugins}/bin/openrgb --profile /home/michael/.config/OpenRGB/Dark.orp";
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

  programs.steam = {
  enable = true;
  gamescopeSession.enable = true; # Enables Gamescope for better gaming experience
  remotePlay.openFirewall = true;
  dedicatedServer.openFirewall = true;
  localNetworkGameTransfers.openFirewall = true;
  };   

  hardware.graphics = {
  enable = true;
  enable32Bit = true;
  };   

  programs = {
  gamescope = {
    enable = true;
    capSysNice = true;
  };
  
};   
}
