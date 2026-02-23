{
  description = "Michael's Multi-PC Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # Add this input
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = { self, nixpkgs, nix-flatpak, ... }@inputs: {
    nixosConfigurations = {
      nixos-laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ 
          nix-flatpak.nixosModules.nix-flatpak # Add this
          ./hosts/laptop/configuration.nix 
          ./common/common.nix
          ./hosts/laptop/battery.nix 
          ./hosts/laptop/storage.nix 
        ];
      };

      nixos-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ 
          nix-flatpak.nixosModules.nix-flatpak # Add this
          ./hosts/desktop/configuration.nix 
          ./common/common.nix 
          ./hosts/desktop/nvidia.nix 
          ./hosts/desktop/hardware-configuration.nix
          ./hosts/desktop/network-storage.nix
        ];
      };
    };
  };
}
