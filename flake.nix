{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs { inherit system; };

      inherit (pkgs.python3Packages) twine build;

      log2compdb = import ./default.nix { inherit pkgs; };

    in {
      packages.default = log2compdb;

      apps.default = flake-utils.lib.mkApp { drv = log2compdb; };

      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.pyright
          twine
          build
        ];
        inputsFrom = [ log2compdb ];
      };

      checks = self.packages.${system};

    }) # eachDefaultSystems
  ; # outputs
}
