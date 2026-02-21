{ config, pkgs, ... }:

{
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
  services.flatpak.enable = true;

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
    nix-direnv
    conda
    gnomeExtensions.dash-to-panel
    gnomeExtensions.arc-menu
    gnomeExtensions.appindicator
    gnome-tweaks
    tailscale
  ];

  # This allows direnv to hook into your bash shell
  programs.bash.interactiveShellInit = ''
    eval "$(direnv hook bash)"
  '';

  services.tailscale.enable = true;

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
    nix-up = "/etc/nixos/rebuild.sh";
  };

  # Limit the Boot Menu Entries
  boot.loader.systemd-boot.configurationLimit = 1;

  # Adding SyncThing to my NixOS Machines
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
  };
}
