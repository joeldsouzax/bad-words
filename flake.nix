{

  description = "mono repo with rust backend with cargo workspaces";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpks-unstable";
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
  outputs = { nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in with pkgs; {
        devShell.default =
          mkShell { buildInputs = [ podman podman-compose dive ]; };
      });
}
