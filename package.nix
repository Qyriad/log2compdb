# pythonPackages.callPackage
{
  lib,
  stdenvNoCC,
  python,
  pythonOlder,
  setuptools,
  pytestCheckHook,
  pypaBuildHook,
  pypaInstallHook,
  pythonCatchConflictsHook,
  # Compatability with Nixpkgs 23.11.
  pythonRuntimeDepsCheckHook ? null,
  pythonNamespacesHook,
  pythonOutputDistHook,
  pythonImportsCheckHook,
  ensureNewerSourcesForZipFilesHook,
  pythonRemoveBinBytecodeHook,
  wrapPython,
  basedpyright ? null,
}: let
  stdenv = stdenvNoCC;
  # FIXME: should this be python.stdenv?
  inherit (stdenv) hostPlatform buildPlatform;
in stdenv.mkDerivation (self: {
  # If we're using an unsupported Python version then put that in the name.
  pname = if !(self.meta.broken or false) then "log2compdb" else "log2compdb-${python.pythonAttr}";
  # log2compdb.__version__ is the source pyproject.toml uses, so we'll
  # use it too.
  version = lib.pipe ./log2compdb/__init__.py [
    builtins.readFile
    (lib.splitString "\n")
    (lib.filter (lib.hasPrefix "__version__ = "))
    (lib.head)
    (lib.removePrefix "__version__ = ")
    # Just parses the string literal, lmao.
    # Poor woman's `ast.literal_eval`.
    (builtins.fromJSON)
  ];

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

  nativeCheckInputs = [
    basedpyright
  ];

  checkPhase = lib.optionalString (basedpyright != null) ''
    runHook preCheck
    echo "$pname:" "checking for type errors with basedpyright"
    basedpyright --warnings --stats
    echo "basedpyright checkPhase complete"
    runHook postCheck
  '';

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
    broken = pythonOlder "3.8";
    mainProgram = "log2compdb";
    maintainers = with lib.maintainers; [ qyriad ];
    isBuildPythonPackage = python.meta.platforms;
  };
})
