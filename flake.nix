{
  description = "Crunchy Nixpkgs";

  nixConfig = {
    extra-substituters = "https://crunchy-public.cachix.org";
    extra-trusted-public-keys = "crunchy-public.cachix.org-1:bsv90PlrrUAFcIA7NoajCWDpddTY2GGXX7XG+C1BMzQ=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        crystal-packages = import ./crystal { inherit pkgs system; };
      in
      {
        packages = crystal-packages;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ cachix jq ];
        };
      }
    );
}
