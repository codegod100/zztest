{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };
inputs.zig.url = "github:mitchellh/zig-overlay";
  outputs =
    { nixpkgs, flake-utils, zig,... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.extend zig.overlays.default;
      in
      {
        devShells.default = pkgs.mkShell { packages = [ pkgs.bashInteractive pkgs.zigpkgs.master]; };
      }
    );
}
