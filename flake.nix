{
  description = "younsl's macOS system and home configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-darwin,
      home-manager,
      rust-overlay,
      ...
    }:
    let
      system = "aarch64-darwin";
      overlays = [ rust-overlay.overlays.default ];
      pkgs = import nixpkgs { inherit system overlays; };

      sudoUser = builtins.getEnv "SUDO_USER";
      user = if sudoUser != "" then sudoUser else builtins.getEnv "USER";
      repoDir = "/Users/${user}/github/younsl/nix";
    in
    {
      darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit user repoDir; };
        modules = [
          {
            nixpkgs.hostPlatform = system;
            nixpkgs.overlays = overlays;
          }
          home-manager.darwinModules.home-manager
          ./nix/darwin
        ];
      };

      packages.${system}.kavd-watchdog = pkgs.callPackage ./nix/pkgs/kavd-watchdog.nix { };

      formatter.${system} = pkgs.nixfmt;
    };
}
