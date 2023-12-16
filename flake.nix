{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (builtins) attrValues;

        mkDefault = drv: {
          default = drv;
          ${drv.pname} = drv;
        };

        log2compdb = pkgs.callPackage ./log2compdb.nix { };

        devShellPkgs = attrValues {
          inherit (pkgs.python3Packages)
            twine
            build
          ;
        };

      in {
        packages = mkDefault log2compdb;

        devShells.default = pkgs.mkShell {
          packages = devShellPkgs;
          inputsFrom = [ log2compdb ];
        };

      }
    ) # eachDefaultSystems
  ; # outputs
}
