{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    qyriad-nur = {
      url = "github:Qyriad/nur-packages";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    qyriad-nur,
  }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
    qpkgs = import qyriad-nur { inherit pkgs; };
    inherit (qpkgs) lib;

    log2compdb = import ./default.nix { inherit pkgs qpkgs; };

    extraVersions = lib.mapAttrs' (pyName: value: {
      name = "${pyName}-cappy";
      inherit value;
    }) log2compdb.byPythonVersion;

  in {
    packages = extraVersions // {
      default = log2compdb;
      inherit log2compdb;
    };

    apps.default = flake-utils.lib.mkApp { drv = log2compdb; };

    devShells.default = pkgs.python3Packages.callPackage log2compdb.mkDevShell { };

    checks = self.packages.${system};
  });
}
