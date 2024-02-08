{
  lib,
  python3,
}: let
  inherit (python3.pkgs)
    buildPythonApplication
    setuptools
    wheel
    pytest
  ;
in buildPythonApplication {
  pname = "log2compdb";
  version = "0.2.5";
  format = "pyproject";

  src = lib.sources.cleanSource ./.;

  meta = {
    description = "Generate compile_commands.json from a build log with compiler invocations";
    homepage = "https://github.com/Qyriad/log2compdb";
    license = lib.licenses.mit;

    # In theory, this works anywhere Python does.
    platforms = python3.meta.platforms;

    mainProgram = "log2compdb";
  };

  checkPhase = "pytest";

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  nativeCheckInputs = [
    pytest
  ];
}
