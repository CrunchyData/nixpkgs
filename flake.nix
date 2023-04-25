{
  description = "Crunchy Nixpkgs";

  nixConfig = {
    extra-substituters = "https://crunchy-public.cachix.org";
    extra-trusted-public-keys = "crunchy-public.cachix.org-1:bsv90PlrrUAFcIA7NoajCWDpddTY2GGXX7XG+C1BMzQ=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ameba-src = { url = "github:crystal-ameba/ameba/v1.4.2"; flake = false; };
  };

  outputs = inputs@{ self, flake-utils, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
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
