{ config, pkgs, ... }:

{
  # 1. Enable the dynamic linker for non-Nix binaries (Conda, VS Code, etc.)
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
  ];

  services.envfs.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Regional Settings
  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_AU.UTF-8";
  
  # Desktop Environment (GNOME)
  services.xserver = {
    enable = true;
    xkb.layout = "au";
  };
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Sound and Printing
  services.printing.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User Account
  users.users.michael = {
    isNormalUser = true;
    description = "Michael McMillan";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # --- SYSTEM PACKAGES ---
  environment.systemPackages = with pkgs; [
    vim wget brave vscode obsidian git direnv
    vesktop nix-direnv conda nmap gnome-tweaks
    gnomeExtensions.dash-to-panel
    gnomeExtensions.arc-menu
    gnomeExtensions.appindicator
    tailscale rclone
  ];

  services.tailscale.enable = true;

  # Force GNOME to show all three window buttons
  programs.dconf.enable = true;
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.desktop.wm.preferences]
    button-layout='appmenu:minimize,maximize,close'
  '';

  services.flatpak = {
    enable = true;
    packages = [
      "com.ticktick.TickTick"
      "com.discordapp.Discord"
      "us.zoom.Zoom"
      "eu.betterbird.Betterbird"
    ];
  };

  # --- AUTOMATION & COMPATIBILITY ---
  programs.nix-ld.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Automatically clear stale Brave locks on boot
  systemd.user.services.clear-brave-lock = {
    description = "Clear Brave SingletonLock on startup";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/rm -f %h/.config/BraveSoftware/Brave-Browser/SingletonLock";
    };
  };

  boot.loader.systemd-boot.configurationLimit = 10; # Limits the boot menu to 10 entries

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d"; # Deletes anything older than 2 weeks
  };

  # Also optimizes the store to save space by linking identical files
  nix.settings.auto-optimise-store = true;
 
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  environment.shellAliases = {
    nix-up = "$HOME/nixos-config/rebuild.sh";
    nix-pull = "git -C $HOME/Documents/nixos-config pull";
    
    # Standardized NAS syncs (Capital M for Remote, slash / for no-nesting)
    nas-pull = "mkdir -p $HOME/Synology_Home && ${pkgs.rsync}/bin/rsync -avzu -e ssh --exclude='@eaDir/' --exclude='@SynoEAStream' --exclude='cmake-build-*/' --exclude='.idea/' --exclude='.vscode*/' --exclude='.cache/' --exclude='.npm/' --exclude='.conda/' --exclude='.docker/' --exclude='.dotnet/' --exclude='#recycle/' Michael@100.90.5.80:/volume1/homes/Michael/ $HOME/Synology_Home/";
    
    nas-push = "mkdir -p $HOME/Synology_Home && ${pkgs.rsync}/bin/rsync -avzu -e ssh --exclude='@eaDir/' --exclude='@SynoEAStream' --exclude='cmake-build-*/' --exclude='.idea/' --exclude='.vscode*/' --exclude='.cache/' --exclude='.npm/' --exclude='.conda/' --exclude='.docker/' --exclude='.dotnet/' --exclude='#recycle/' $HOME/Synology_Home/ Michael@100.90.5.80:/volume1/homes/Michael/";

    uni-pull = "${pkgs.rsync}/bin/rsync -avzu -e ssh --exclude='.conda/' --exclude='.ipynb_checkpoints/' --exclude='__MACOSX/' --exclude='cmake-build-*/' michael@100.70.100.118:/home/michael/University/ $HOME/Documents/University/";
    uni-push = "${pkgs.rsync}/bin/rsync -avzu -e ssh --exclude='.conda/' --exclude='.ipynb_checkpoints/' --exclude='__MACOSX/' --exclude='cmake-build-*/' $HOME/Documents/University/ michael@100.70.100.118:/home/michael/University/";    
  };
  
  # Sync the synology home folder
  systemd.user.services.daily-nas-sync = {
    description = "Daily Mirror Sync to Synology (Safe Delete)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeScript "safe-sync" ''
        #!${pkgs.bash}/bin/bash
        mkdir -p /home/michael/Documents/Synology_Home
        if [ $(ls -A /home/michael/Documents/University | wc -l) -gt 0 ]; then
          ${pkgs.rsync}/bin/rsync -avzu --delete /home/michael/Documents/University/ Michael@100.90.5.80:/volume1/homes/Michael/University/
        else
          ${pkgs.rsync}/bin/rsync -avzu /home/michael/Documents/Synology_Home Michael@100.90.5.80:/volume1/homes/Michael
        fi
      '';
    };
  };
  
  # Systemd service for daily iterative backup
  systemd.user.services.daily-uni-backup = {
    description = "Daily Iterative University Backup to Synology";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = let
        date = "$(date +%Y-%m-%d_%H-%M)";
      in pkgs.writeScript "uni-backup-script" ''
        #!${pkgs.bash}/bin/bash
        # 1. Run the iterative backup
        ${pkgs.rclone}/bin/rclone copy /home/michael/Documents/University/ nas-home:University/ \
          --backup-dir nas-home:University_Archive/${date} \
          --exclude '.conda/**' --exclude '.ipynb_checkpoints/**' --exclude 'cmake-build-/**' \
          --progress

        # 2. Rotate archives: Keep only the 5 most recent folders
        ${pkgs.rclone}/bin/rclone lsf nas-home:University_Archive/ | sort -r | tail -n +6 | xargs -I{} ${pkgs.rclone}/bin/rclone purge nas-home:University_Archive/{}
      '';
    };
  };

  # The Timer to trigger the service
  systemd.user.timers.daily-uni-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true; # Ensures it runs at next boot if the laptop was off
      Unit = "daily-uni-backup.service";
    };
  };

  systemd.user.timers.daily-nas-sync = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true; # Runs at next boot if the laptop was off
      Unit = "daily-nas-sync.service";
    };
  };
  
  # Standardizing the Service
  systemd.user.services.sync-university = {
    description = "Hourly Sync of University folders from Mini-PC Hub";
    wantedBy = [ "graphical-session.target" ];
    path = with pkgs; [ rsync openssh bash coreutils ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeScript "sync-university-script" ''
        #!${pkgs.bash}/bin/bash
        DEST="$HOME/Documents/University"
        # SAFETY: Only run if the local folder isn't broken and hub is up
        if ssh -o ConnectTimeout=5 michael@100.70.100.118 "[ -d /home/michael/University/UOW ]"; then
            ${pkgs.rsync}/bin/rsync -avzu -e ssh \
              --exclude='*.sh' --exclude='*.txt' --exclude='cmake-build-*/' \
              michael@100.70.100.118:/home/michael/University/ "$DEST/"
        fi
      '';
    };
  };
  # Timer to run the sync every 1 hour
  systemd.user.timers.sync-university-timer = {
    description = "Run University sync every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "1h";
      Unit = "sync-university.service";
    };
  };  

  # SSH Client Configuration
  programs.ssh = {
    extraConfig = ''
      Host 100.90.5.80
          HostName 100.90.5.80
          User Michael
          # This silences the specific post-quantum warning for your NAS
          WarnWeakCrypto no
    '';
  };

  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
  networking.enableIPv6 = false;
  
  programs.bash.interactiveShellInit = ''
    # 1. Safely check if conda is in the system path
    if [ -x /run/current-system/sw/bin/conda ]; then
      eval "$(/run/current-system/sw/bin/conda shell.bash hook)"
    fi

    # 2. Existing hooks
    eval "$(direnv hook bash)"

    show_conda_env() {
      if [ -n "$CONDA_PREFIX" ]; then
        echo "($(basename "$CONDA_PREFIX")) "
      fi
    }

    PROMPT_COMMAND='PS1="\[\033[1;34m\]$(show_conda_env)\[\033[1;32m\]\u\[\033[1;33m\]@\h\[\033[00m\]:\[\033[1;36m\]\w\[\033[00m\]\$ "'
  '';
}
