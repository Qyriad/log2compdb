# pythonPackages.callPackage
{
  lib,
  stdenvNoCC,
  python,
  setuptools,
  pytestCheckHook,
  pypaBuildHook,
  pypaInstallHook,
  pythonCatchConflictsHook,
  pythonRuntimeDepsCheckHook,
  pythonNamespacesHook,
  pythonOutputDistHook,
  pythonImportsCheckHook,
  ensureNewerSourcesForZipFilesHook,
  pythonRemoveBinBytecodeHook,
  wrapPython,
}: let
  stdenv = stdenvNoCC;
  # FIXME: should this be python.stdenv?
  inherit (stdenv) hostPlatform buildPlatform;
in stdenv.mkDerivation (self: {
  pname = "log2compdb";
  version = "0.2.5";

  strictDeps = true;
  __structuredAttrs = true;

  doCheck = true;
  doInstallCheck = true;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./pyproject.toml
      ./log2compdb
      ./tests
    ];
  };

  outputs = [ "out" "dist" ];

  nativeBuildInputs = [
    pypaBuildHook
    pypaInstallHook
    pythonRuntimeDepsCheckHook
    pythonOutputDistHook
    ensureNewerSourcesForZipFilesHook
    pythonRemoveBinBytecodeHook
    wrapPython
    setuptools
  ] ++ lib.optionals (buildPlatform.canExecute hostPlatform) [
    pythonCatchConflictsHook
  ] ++ lib.optionals (python.pythonAtLeast "3.3") [
    pythonNamespacesHook
  ];

  nativeInstallCheckInputs = [
    pythonImportsCheckHook
    pytestCheckHook
  ];

  postFixup = ''
    echo "Wrapping Python programs in postFixup..."
    wrapPythonPrograms
    echo "done wrapping Python programs in postFixup"
  '';

  passthru.mkDevShell = {
    mkShellNoCC,
    pylint,
    basedpyright,
    twine,
    build,
  }: mkShellNoCC {
    inputsFrom = [ self.finalPackage ];
    packages = [
      pylint
      basedpyright
      twine
      build
    ];
  };

  meta = {
    description = "Generate compile_commands.json from a build log with compiler invocations";
    homepage = "https://github.com/Qyriad/log2compdb";
    license = lib.licenses.mit;
    # In theory, this works anywhere Python does.
    platforms = python.meta.platforms;
    mainProgram = "log2compdb";
    maintainers = with lib.maintainers; [ qyriad ];
    isBuildPythonPackage = python.meta.platforms;
  };
})
