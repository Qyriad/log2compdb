{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };

      log2compdb = pkgs.python3Packages.buildPythonApplication {

        pname = "log2compdb";
        version = "0.2.5";
        format = "pyproject";
        src = ./.;

        buildInputs = with pkgs.python3Packages; [
          setuptools
          wheel
        ];
      };

    in {

      devShells.default = pkgs.mkShell {
        packages = [
          log2compdb
        ];
      };
      packages.default = log2compdb;
      applications.default = log2compdb;
    }
  );
}
