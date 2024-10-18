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
      in { devShells.default = craneLib.devShell { }; });
}
