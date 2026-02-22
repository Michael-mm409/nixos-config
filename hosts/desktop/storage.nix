{ config, pkgs, ... }: {
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/a3886784-3f1a-41d4-8428-8852c13a71e8";
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
