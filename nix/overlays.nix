final: prev: {
  # nixpkgs ties pre-commit to a dotnet SDK that has no darwin cache and builds from source for hours
  pre-commit = prev.pre-commit.overridePythonAttrs {
    doCheck = false;
    doInstallCheck = false;
    dontUsePytestCheck = true;
    nativeCheckInputs = [ ];
    env = { };
  };

  # its integration tests fail inside the darwin build sandbox and darwin has no cached build
  cargo-llvm-cov = prev.cargo-llvm-cov.overrideAttrs { doCheck = false; };
}
