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
  
  systemd.user.services.daily-nas-sync = {
    Unit.Description = "Daily Mirror Sync to Synology";
    Service = {
      Type = "oneshot"; # Explicitly define as a single-run task
      ExecStart = "${pkgs.rsync}/bin/rsync -avzu /home/michael/Documents/University/ Michael@100.90.5.80:/volume1/homes/Michael/University/";
    };
  };

  programs.home-manager.enable = true;

  # User-level Services for University Backups
  systemd.user.services.daily-uni-backup = {
    Unit.Description = "Daily Iterative University Backup to Synology";
    Service = {
      Type = "oneshot";
      ExecStart = let
        date = "$(date +%Y-%m-%d_%H-%M)";
      in pkgs.writeScript "uni-backup-script" ''
        #!${pkgs.bash}/bin/bash
        # 1. Run the iterative backup using rclone
        ${pkgs.rclone}/bin/rclone copy $HOME/Documents/University/ nas-home:University/ \
          --backup-dir nas-home:University_Archive/${date} \
          --exclude '.conda/**' --exclude '.ipynb_checkpoints/**' \
          --progress

        # 2. Rotate archives: Keep only the 5 most recent folders
        ${pkgs.rclone}/bin/rclone lsf nas-home:University_Archive/ | sort -r | tail -n +6 | \
          xargs -I{} ${pkgs.rclone}/bin/rclone purge nas-home:University_Archive/{}
      '';
    };
  };

  # The Timer to trigger it daily
  systemd.user.timers.daily-uni-backup = {
    Install.WantedBy = [ "timers.target" ];
    Timer = {
      OnCalendar = "daily";
      Persistent = true; # Runs at boot if the laptop was off during the scheduled time [cite: 37]
    };
  };

  # Manage rclone config file
  home.file.".config/rclone/rclone.conf".text = ''
    [nas-home]
    type = sftp
    host = 100.90.5.80
    user = Michael
    port = 22
    shell_type = unix
    md5sum_command = md5sum
    sha1sum_command = sha1sum
  '';
}
