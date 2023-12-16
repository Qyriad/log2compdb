{
  pkgs ? import <nixpkgs> { },
}:
  pkgs.callPackage ./log2compdb.nix { }
