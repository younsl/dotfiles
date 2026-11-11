{ pkgs, ... }:
let
  kavd-watchdog = pkgs.callPackage ../pkgs/kavd-watchdog.nix { };
in
{
  launchd.daemons.kavd-watchdog.serviceConfig = {
    Label = "local.kavd-watchdog";
    ProgramArguments = [
      "${kavd-watchdog}/bin/kavd-watchdog"
      "--service"
      "system/com.kaspersky.kav.kavd"
    ];
    RunAtLoad = true;
    KeepAlive = true;
    StandardOutPath = "/var/log/kavd-watchdog.log";
    StandardErrorPath = "/var/log/kavd-watchdog.log";
  };
}
