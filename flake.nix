{
  description = "mono repo with rust backend with cargo workspaces";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-annalyzer-src.follows = "";
      };
    };
  };
  outputs = { nixpkgs, utils, crane, fenix, ... }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        backend =
          import ./build/backend.nix { inherit pkgs crane fenix system; };
      in with pkgs; {
        checks = {
          questions = backend.questions;
          workspace-clippy = backend.workspace-clippy;
        };
        devShells.default =
          mkShell { buildInputs = [ podman podman-compose dive ]; };
      });
}
