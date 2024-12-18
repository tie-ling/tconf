{
  description = "NixOS configuration with flakes";
  # https://channels.nixos.org/nixos-24.11/git-revision
  # https://channels.nixos.org/nixos-unstable/git-revision
  inputs.nixpkgs.url = "nixpkgs/970e93b9f82e2a0f3675757eb0bfc73297cc6370";
  inputs.disko.url = "github:nix-community/disko/latest";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      self,
      nixpkgs,
      disko,
    }@inputs:
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      nixosConfigurations.hp-840g3 = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          disko.nixosModules.disko
          ./hp-840g3/configuration.nix
          ./hp-840g3/disko.nix
        ];
      };

      nixosConfigurations.tieling = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          disko.nixosModules.disko
          ./server/configuration.nix
          ./server/disko.nix
        ];
      };
      nixosConfigurations.player = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          disko.nixosModules.disko
          ./player/configuration.nix
          ./player/disko.nix
        ];
      };
    };
}
