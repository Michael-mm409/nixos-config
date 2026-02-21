{ config, pkgs, ... }: {
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/22985a39-abf7-4ed3-806b-f1e0dda4923d";
    fsType = "btrfs";
    # Optimized for your high-performance desktop NVMe
    options = [ 
      "subvol=@home" 
      "compress=zstd" 
      "noatime" 
      "ssd" 
      "discard=async" 
    ];
  };
}
