{
  description = "Plik";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    forEachSystem = nixpkgs.lib.genAttrs systems;
  in {
    packages = forEachSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
        plik = pkgs.callPackage ./package.nix {inherit nixpkgs system;};
      in {
        inherit plik;
        default = plik;
      }
    );

    defaultPackage = forEachSystem (system: self.packages.${system}.plik);

    nixosModules.default = import ./module.nix {
      inherit nixpkgs self;
    };
  };
}
