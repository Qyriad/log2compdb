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

        meta = {
          description = "Generate compile_commands.json from a build log with compiler invocations";
          homepage = "https://github.com/Qyriad/log2compdb";
          license = pkgs.lib.licenses.mit;

          # In theory, this works anywhere Python does.
          platforms = pkgs.python3.meta.platforms;
        };

        nativeBuildInputs = with pkgs.python3Packages; [
          setuptools
          wheel
        ];

        nativeCheckInputs = with pkgs.python3Packages; [
          pytest
        ];

        checkPhase = "pytest";
      };

      devShellPkgs = with pkgs.python3Packages; [
        build
        twine
      ];

    in {

      packages.default = log2compdb;

      devShells.default = pkgs.mkShell {
        packages = devShellPkgs;
        inputsFrom = [ log2compdb ];
      };

      devShells.user = pkgs.mkShell {

        meta = {
          description = "Like devShells.default, but will exec $USERSHELL.";
        };

        packages = devShellPkgs;
        inputsFrom = [ log2compdb ];

        shellHook = ''
          [[ -z "$USERSHELL" ]] && \
            echo 'Set $USERSHELL to use `nix shell`/`nix develop` with your preferred shell' ; \
            exit 1
          exec $USERSHELL
        '';
      };
    }
  );
}
