{ lib, pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "clone-all";
      runtimeInputs = with pkgs; [
        coreutils
        curl
        gawk
        git
        jq
      ];
      text = builtins.readFile ../../scripts/git/clone-all.sh;
    })
    (pkgs.runCommand "kubectl-stern" { } ''
      mkdir -p $out/bin
      ln -s ${lib.getExe pkgs.stern} $out/bin/kubectl-stern
    '')
  ];
}
