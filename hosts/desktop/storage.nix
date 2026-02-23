{
  # Ensure these three blocks match exactly in storage.nix
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/72728c17-a00b-4d9c-b31f-34927c34a367"; # Physical nvme1n1p1
    fsType = "btrfs";
    options = [ "subvol=@"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/CA38-BF18"; # Physical nvme1n1p2
    fsType = "vfat";
  };
  
  fileSystems."/home" = {
    # Add the semicolon after the UUID string below
    device = "/dev/disk/by-uuid/5e542145-466e-41c5-8056-ec37fa87905c"; 
    fsType = "btrfs";
    options = [ "subvol=@home" ];
  };
 } # THIS FINAL BRACE IS LIKELY WHAT IS MISSING
