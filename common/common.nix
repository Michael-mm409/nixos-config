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
    # Add any other libraries your ML models/Data Science tools might need
  ];

  # 2. Map standard paths like /bin/bash for scripts
  services.envfs.enable = true;

  # Allow unfree software (Brave, VS Code, etc.)
  nixpkgs.config.allowUnfree = true;

  # Regional Settings
  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_AU.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

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
    vim
    wget
    brave
    vscode
    obsidian
    git
    direnv
    vesktop # Optional: Great for better screen sharing on Wayland/GNOME
    nix-direnv
    conda
    gnomeExtensions.dash-to-panel
    gnomeExtensions.arc-menu
    gnomeExtensions.appindicator
    gnome-tweaks
    tailscale
    conda
    nmap
  ];

  services.tailscale.enable = true;

  # Force GNOME to show all three window buttons
  programs.dconf.enable = true;

  services.flatpak = {
    enable = true;
    update.onActivation = true; # Automatically updates apps on rebuild
    packages = [
      "com.ticktick.TickTick"     # Version 8.0.0
      "com.discordapp.Discord"   # No more update-loop breaks
      "us.zoom.Zoom"
      "eu.betterbird.Betterbird"
    ];
  };

  /*
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.desktop.wm.preferences]
    button-layout='appmenu:minimize,maximize,close'
  '';
*/
  # --- AUTOMATION & COMPATIBILITY ---
  programs.nix-ld.enable = true; # Needed for Conda/VS Code binaries
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # NUR (Nix User Repository) setup
  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  # Automatically clear stale Brave locks on boot
  systemd.user.services.clear-brave-lock = {
    description = "Clear Brave SingletonLock on startup";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/rm -f %h/.config/BraveSoftware/Brave-Browser/SingletonLock";
    };
  };
 
  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.shellAliases = {
    # This now runs your script which handles git add, build, and commit
    nix-up = "$HOME/nixos-config/rebuild.sh";
  };

  # Limit the Boot Menu Entries
  boot.loader.systemd-boot.configurationLimit = 5;

  # Adding SyncThing to my NixOS Machines
/*
  services.syncthing = {
    enable = true;
    user = "michael";
    dataDir = "/home/michael/Documents";    # Default folder for synced data
    configDir = "/home/michael/.config/syncthing";
    overrideDevices = true;     # Allows you to manage devices via Nix
    overrideFolders = true;     # Allows you to manage folders via Nix
    settings = {
      devices = {
        "Mini-PC" = { id = "DEVICE-ID-OF-YOUR-MINI-PC"; };
        "Synology-NAS" = { id = "DEVICE-ID-OF-YOUR-NAS"; };
      };
      folders = {
        "University" = {        # Your Master of Data Science work
          path = "/home/michael/Documents/University";
          devices = [ "Mini-PC" "Synology-NAS" ];
        };
        "Obsidian" = {          # Your linked knowledge base
          path = "/home/michael/Documents/Obsidian";
          devices = [ "Mini-PC" "Synology-NAS" ];
        };
      };
    };
  };*/

  networking.nameservers =
  [ "1.1.1.1" "8.8.8.8" ];
  networking.enableIPv6 = false;

  programs.bash.interactiveShellInit = ''
    # 1. Essential: Hook direnv into your shell
    eval "$(direnv hook bash)"

    # 2. Robust function to show the Conda env
    show_conda_env() {
      if [ -n "$CONDA_PREFIX" ]; then
        echo "($(basename "$CONDA_PREFIX")) "
      fi
    }

    
    # 3. Use the 'prompt' variable if PS1 is being overwritten
    # We use \[ \] to tell bash these are non-printing characters (prevents weird wrapping)
    # 1;34m is Bold Blue

    # 3.1 COLOR SCHEME
    # \[ \033[1;34m \] -> Bold Blue (Conda Env)
    # \[ \033[1;32m \] -> Bold Green (Username)
    # \[ \033[1;33m \] -> Bold Yellow (@Host)
    # \[ \033[1;36m \] -> Bold Cyan (Current Path)
    # \[ \033[0m \]    -> Reset to white

    PROMPT_COMMAND='PS1="\[\033[1;34m\]$(show_conda_env)\[\033[1;32m\]\u\[\033[1;33m\]@\h\[\033[00m\]:\[\033[1;36m\]\w\[\033[00m\]\$ "'

  '';
}
