{ config, pkgs, lib, ... }:

{
  home.username = "michael";
  home.homeDirectory = lib.mkForce "/home/michael";
  home.stateVersion = "24.11"; 

  # Standardized NAS and University syncs (Unified from common.nix)
  home.shellAliases = {
    nix-up = "home-manager switch --flake ~/nixos-config#$(hostname)";
    nas-pull = "mkdir -p $HOME/Synology_Home && ${pkgs.rsync}/bin/rsync -avzu -e ssh --exclude='.conda/' Michael@100.90.5.80:/volume1/homes/Michael/ $HOME/Synology_Home/";
    nas-push = "mkdir -p $HOME/Synology_Home && ${pkgs.rsync}/bin/rsync -avzu -e ssh --exclude='.conda/' $HOME/Synology_Home/ Michael@100.90.5.80:/volume1/homes/Michael/";
    uni-pull = "${pkgs.rsync}/bin/rsync -avzu -e ssh --exclude='.conda/' michael@100.70.100.118:/home/michael/University/ $HOME/Documents/University/";
    uni-push = "${pkgs.rsync}/bin/rsync -avzu -e ssh --exclude='.conda/' $HOME/Documents/University/ michael@100.70.100.118:/home/michael/University/";
  };

  # Activation script to ensure your University/NAS folders exist on Fedora
  home.activation = {
    createUniFolders = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p $HOME/Documents/University
      mkdir -p $HOME/Synology_Home
    '';
  };

  # Shared User Packages (Apps you want everywhere)
  home.packages = with pkgs; [
    brave obsidian vscode git wget direnv rclone tailscale vesktop
  ];

  # User-level background syncs (Moved from common.nix)
  systemd.user.services.daily-nas-sync = {
    Unit.Description = "Daily Mirror Sync to Synology";
    Service.ExecStart = "${pkgs.rsync}/bin/rsync -avzu /home/michael/Documents/University/ Michael@100.90.5.80:/volume1/homes/Michael/University/";
  };
  
  systemd.user.timers.daily-nas-sync = {
    Install.WantedBy = [ "timers.target" ];
    Timer = { OnCalendar = "daily"; Persistent = true; };
  };

  programs.home-manager.enable = true;
}
