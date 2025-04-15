{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
    log2compdb = import ./default.nix { inherit pkgs; };

  in {
    packages = {
      default = log2compdb;
      inherit log2compdb;
    };

    apps.default = flake-utils.lib.mkApp { drv = log2compdb; };

    devShells.default = pkgs.python3Packages.callPackage log2compdb.mkDevShell { };

    checks = self.packages.${system};
  });
}
