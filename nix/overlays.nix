final: prev: {
  # nixpkgs ties pre-commit to a dotnet SDK that has no darwin cache and builds from source for hours
  pre-commit = prev.pre-commit.overridePythonAttrs {
    doCheck = false;
    nativeCheckInputs = [ ];
    env = { };
  };
}
