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
  };

  boot.loader.systemd-boot.configurationLimit = 5;

  # Adding SyncThing - FIXED NESTING
  services.syncthing = {
    enable = true;
    user = "michael";
    dataDir = "/home/michael/Documents";
    configDir = "/home/michael/.config/syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        "Mini-PC" = { 
          id = "Z6LOPPW-OWK2ZVY-W4DVQTF-7NR42TU-UXRGMJ4-RN2LZ3I-LWROXH2-TD3BPA4"; 
          addresses = [ "tcp://100.70.100.118" ]; 
        };
        "Synology-NAS" = { 
          id = "YODIB4K-XHNL3CB-VVEHUJM-YDSBTHU-EZB4AVN-VO3XDCI-F7EQNW7-NCUQLAT"; 
          addresses = [ "tcp://100.90.5.80" ]; 
        };
      };
      folders = {
        "University" = {
          id = "University"; 
          path = "/home/michael/Documents/University";
          devices = [ "Mini-PC" "Synology-NAS" ];
        };
      };

      gui = {
        address = "127.0.0.1:8384"; # Local access only for security
      };

      options = {
        listenAddresses = [ "default" "tcp://0.0.0.0:22000" "quic://0.0.0.0:22000" ];
        localAnnounceEnabled = true;
        globalAnnounceEnabled = true;
        relaysEnabled = true;
        urAccepted = -1; # Disables usage reporting
      };
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
