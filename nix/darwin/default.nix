{ user, repoDir, ... }:
{
  imports = [
    ./homebrew.nix
    ./kavd-watchdog.nix
  ];

  assertions = [
    {
      assertion = user != "" && user != "root";
      message = "Run darwin-rebuild through sudo with --impure so SUDO_USER resolves to the login user.";
    }
  ];

  nix.enable = false;

  system = {
    primaryUser = user;
    stateVersion = 6;
    defaults.CustomUserPreferences."com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
  };

  users.users.${user}.home = "/Users/${user}";

  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "pre-nix";
    extraSpecialArgs = { inherit repoDir; };
    users.${user} = import ../home;
  };
}
