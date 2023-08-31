{
  description = "Crunchy Nixpkgs";

  nixConfig = {
    extra-substituters = "https://crunchy-public.cachix.org";
    extra-trusted-public-keys = "crunchy-public.cachix.org-1:bsv90PlrrUAFcIA7NoajCWDpddTY2GGXX7XG+C1BMzQ=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crystal-src = { url = "github:crystal-lang/crystal/release/1.9"; flake = false; };
    ameba-src = { url = "github:crystal-ameba/ameba"; flake = false; };
  };

  outputs = inputs@{ self, flake-utils, nixpkgs, ... }:
    {
      lib.crystal = import ./crystal/lib.nix;
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        crystal = import ./crystal { inherit pkgs system inputs; };
      in
      {
        packages = crystal.packages;
        checks = crystal.checks;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ cachix jq ];
        };
      }
    );
}
