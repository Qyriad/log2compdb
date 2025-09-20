{
  pkgs ? import <nixpkgs> { },
  python3Packages ? pkgs.python3Packages,
  qpkgs ? let
    src = fetchTarball "https://github.com/Qyriad/nur-packages/archive/main.tar.gz";
  in import src { inherit pkgs; },
}: let
  inherit (qpkgs) lib;

  log2compdb = python3Packages.callPackage ./package.nix { };

  overrideCall = scope: scope.callPackage log2compdb.override { };
  # nb: the parentheses here are unnecessary but it looks fucking weird.
  notDisabled = p: !(p.meta.disabled or false);

  byPythonVersion = lib.pipe qpkgs.pythonScopes [
    (lib.mapAttrs (lib.const overrideCall))
    (lib.filterAttrs (lib.const notDisabled))
  ];

in log2compdb.overrideAttrs (prev: {
  passthru = prev.passthru or { } // {
    inherit byPythonVersion;
  };
})
