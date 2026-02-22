{
  # Ensure these three blocks match exactly in storage.nix
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5aa2bd3d-ae1e-4b1e-b0bd-e42d6f57ceba"; # Physical nvme1n1p1
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/83D8-A151"; # Physical nvme1n1p2
    fsType = "vfat";
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/a3886764-3f1a-41d4-8428-8852c13a71e8"; # Physical nvme1n1p3
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" ];
  };
} # <--- THIS FINAL BRACE IS LIKELY WHAT IS MISSING
