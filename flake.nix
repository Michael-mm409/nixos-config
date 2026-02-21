{
  description = "Michael's Multi-PC Config";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      # Matches hostname 'nixos-laptop'
      nixos-laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ 
          ./hosts/laptop/configuration.nix 
          ./common/common.nix
          ./hosts/laptop/battery.nix 	# Only for laptop!
	  ./hosts/laptop/storage.nix	# Laptop-specific UUID here
        ];
      };

      # Matches hostname 'nixos-desktop'
      nixos-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ 
          ./hosts/desktop/configuration.nix 
          ./common/common.nix			# My shared identity/apps
          ./hosts/desktop/nvidia.nix		# Your 5070-TI drivers
	  ./hosts/desktop/storage.nix		# My BTRFS storage logic
        ];
      };
    };
  };
}
