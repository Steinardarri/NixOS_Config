{
  description = "NixOS configuration";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

  inputs.nixos-wsl.url = "github:nix-community/NixOS-WSL";
  inputs.nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

  inputs.home-manager.url = "github:nix-community/home-manager/release-23.11";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nur.url = "github:nix-community/NUR";

  inputs.nix-index-database.url = "github:Mic92/nix-index-database";
  inputs.nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs:
    with inputs; let
      secrets = builtins.fromJSON (builtins.readFile "${self}/secrets/secrets.json");

      nixpkgsWithOverlays = with inputs; rec {
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            # add any insecure packages you absolutely need here
          ];
        };
        overlays = [
          nur.overlay
          (_final: prev: {
            # this allows us to reference pkgs.unstable
            unstable = import nixpkgs-unstable {
              inherit (prev) system;
              inherit config;
            };
          })
        ];
      };

      configurationDefaults = args: {
        nixpkgs = nixpkgsWithOverlays;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = args;
      };

      argDefaults = {
        inherit secrets inputs self nix-index-database sops-nix;
        channels = {
          inherit nixpkgs nixpkgs-unstable;
        };
      };

      mkNixosConfiguration = {
        system ? "x86_64-linux",
        hostname,
        username,
        args ? {},
        modules,
      }: let
        specialArgs = argDefaults // {inherit hostname username;} // args;
      in
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules =
            [
              (configurationDefaults specialArgs)
              home-manager.nixosModules.home-manager
            ]
            ++ modules;
        };
    in {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

      nixosConfigurations.wsl = mkNixosConfiguration {
        hostname = "wsl";
        username = "nixos";
        modules = [
          nixos-wsl.nixosModules.wsl
          /hosts/wsl/config.nix
        ];
      };
      nixosConfigurations.wsl = mkNixosConfiguration {
        hostname = "heima";
        username = "steinardth";
        modules = [
          ./hosts/heima/config.nix
        ];
      };

    };
}
