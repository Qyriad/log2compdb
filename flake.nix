{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs { inherit system; };

      inherit (pkgs.python3Packages) twine build;

        log2compdb = pkgs.callPackage ./package.nix { };

        hello = pkgs.hello.overrideAttrs (prev: {
          nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [
            log2compdb
          ];
        });

    in {
      packages.default = log2compdb;
      packages.hello = hello;

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
