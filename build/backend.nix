{ pkgs, crane, fenix, system }:
let
  inherit (pkgs) lib;
  craneLib = crane.mkLib pkgs;
  src = craneLib.cleanCargoSource ../backend;

  commonArgs = {
    inherit src;
    strictDeps = true;
    buildInputs = [ ] ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.libiconv ];
  };

  craneLibLLvmTools = craneLib.overrideToolchain
    (fenix.packages.${system}.complete.withComponents [
      "cargo"
      "llvm-tools"
      "rustc"
    ]);

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  individualCrateArgs = commonArgs // {
    inherit cargoArtifacts;
    inherit (craneLib.crateNameFromCargoToml { inherit src; }) version;
    doCheck = false;
  };

  fileSetForCrate = crate:
    lib.fileset.toSource {
      root = ../backend;
      fileset = lib.fileset.unions [
        ../backend/Cargo.toml
        ../backend/Cargo.lock
        ../backend/handle-errors
        crate
      ];
    };

  questions = craneLib.buildPackage (individualCrateArgs // {
    pname = "questions";
    cargoExtraArgs = "-p questions";
    src = fileSetForCrate ../backend/questions;
  });
in {
  questions = questions;
  workspace-clippy = craneLib.cargoClippy (commonArgs // {
    inherit cargoArtifacts;
    cargoClippyExtraArgs = "--all-targets -- --deny warnings";
  });

  workspace-llvm-coverage =
    craneLibLLvmTools.cargoLlvmCov (commonArgs // { inherit cargoArtifacts; });

  backendShell = craneLib.devShell;
}
