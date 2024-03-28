{
  description = "Crunchy Nixpkgs";

  nixConfig = {
    extra-substituters = "https://crunchy-public.cachix.org";
    extra-trusted-public-keys = "crunchy-public.cachix.org-1:bsv90PlrrUAFcIA7NoajCWDpddTY2GGXX7XG+C1BMzQ=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    lastGoodStaticBoehmgc.url = "github:NixOS/nixpkgs/14feac318eefa31d936d9b6a2aacb1928899abfe";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, flake-utils, nixpkgs, lastGoodStaticBoehmgc, ... }:
    {
      lib.crystal = import ./crystal/lib.nix;
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        staticBoehmgc = lastGoodStaticBoehmgc.legacyPackages.${system}.pkgsStatic.boehmgc;
        crystal = import ./crystal { inherit pkgs system inputs staticBoehmgc; };
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
