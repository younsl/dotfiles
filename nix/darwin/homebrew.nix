{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    taps = [
      {
        name = "atlassian/acli";
        trusted = true;
      }
    ];
    brews = [
      "atlassian/acli/acli"
      "tofuenv"
      "wifi-password"
    ];
    casks = [
      "claude-code@latest"
      "ghostty"
      "google-chrome"
      "macshot"
      "rectangle"
      "session-manager-plugin"
      "slack"
      "stats"
      "windows-app"
    ];
    goPackages = [ "helm.sh/helm/v3/cmd/helm" ];
    cargoPackages = [ "vlt" ];
  };
}
