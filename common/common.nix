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
    tailscale
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
 
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  environment.shellAliases = {
    nix-up = "$HOME/nixos-config/rebuild.sh";
    # SAFE PULL: Get files from Hub to Local (Update only, no delete)
    uni-pull = "${pkgs.rsync}/bin/rsync -avzu -e ssh michael@100.70.100.118:/home/michael/University/ $HOME/Documents/University/";
    
    # SAFE PUSH: Send local changes to Hub (Update only, no delete)
    uni-push = "${pkgs.rsync}/bin/rsync -avzu -e ssh \
      --exclude='.conda/' \
      --exclude='.ipynb_checkpoints/' \
      --exclude='__MACOSX/' \
      --exclude='cmake-build-*/' \
      $HOME/Documents/University/ michael@100.70.100.118:/home/michael/University/";
  };
  
  boot.loader.systemd-boot.configurationLimit = 5;
  
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

  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
  networking.enableIPv6 = false;

  programs.bash.interactiveShellInit = ''
    eval "$(direnv hook bash)"

    show_conda_env() {
      if [ -n "$CONDA_PREFIX" ]; then
        echo "($(basename "$CONDA_PREFIX")) "
      fi
    }

    PROMPT_COMMAND='PS1="\[\033[1;34m\]$(show_conda_env)\[\033[1;32m\]\u\[\033[1;33m\]@\h\[\033[00m\]:\[\033[1;36m\]\w\[\033[00m\]\$ "'
  '';
}
