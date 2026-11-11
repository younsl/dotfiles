{
  lib,
  makeRustPlatform,
  rust-bin,
}:
let
  src = ../../configs/launchd/kavd-watchdog;
  manifest = (lib.importTOML (src + "/Cargo.toml")).package;
  toolchain = rust-bin.stable.${manifest.rust-version}.minimal;
  rustPlatform = makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  };
in
rustPlatform.buildRustPackage {
  pname = manifest.name;
  inherit (manifest) version;
  inherit src;
  cargoLock.lockFile = src + "/Cargo.lock";
  meta.mainProgram = manifest.name;
}
