{
  description = "mono repo with rust backend with cargo workspaces";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, utils, crane, fenix, ... }:
    utils.lib.eachDefaultSystem (system:
      let
        # setup all important functions
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;
        # rust backend
        craneLib = crane.mkLib pkgs;
        src = craneLib.cleanCargoSource ./backend;

        commonArgs = {
          inherit src;
          strictDeps = true;
          nativeBuildInputs = lib.optionals pkgs.stdenv.isDarwin
            (with pkgs.darwin.apple_sdk.frameworks; [
              pkgs.libiconv
              CoreFoundation
              Security
              SystemConfiguration
            ]);
        };

        craneLibLLvmTools =
          craneLib.overrideToolchain (fenix.packages.${system}.complete);
        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        individualCrateArgs = commonArgs // {
          inherit cargoArtifacts;
          inherit (craneLib.crateNameFromCargoToml { inherit src; }) version;
          doCheck = false;
        };

        fileSetForBackend = crate:
          lib.fileset.toSource {
            root = ./backend;
            fileset = lib.fileset.unions [
              ./backend/Cargo.toml
              ./backend/Cargo.lock
              ./backend/handle-errors
              crate
            ];
          };
        questions-backend = craneLib.buildPackage (individualCrateArgs // {
          pname = "questions";
          cargoExtraArgs = "-p questions";
          src = fileSetForBackend ./backend/questions;
        });
        # TODO: add filters for sqlx migrations
      in with pkgs; {
        packages = {
          inherit questions-backend;
        } // lib.optionalAttrs (!stdenv.isDarwin) {
          backend-llvm-coverage = craneLibLLvmTools.cargoLlvmCov
            (commonArgs // { inherit cargoArtifacts; });
        };

        devShells.default = craneLib.devShell {
          packages = [ podman podman-compose dive rust-analyzer-nightly ];
        };
      });
}
