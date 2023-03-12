{
  description = "A collection of Nix packages for Crunchy Data.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    golangci-lint.url = "path:./golangci-lint";
  };

  outputs = { self, nixpkgs, golangci-lint }:
  let
    utils = import ./lib/utils.nix;
  in
  utils.eachDefaultSystem (system:
    let
    pkgs = import nixpkgs { inherit system; };
    in {
      packages = {
        golangci-lint = golangci-lint.outputs.defaultPackage.${system};
      };
    });
}
