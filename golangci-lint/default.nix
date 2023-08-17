{ pkgs, system, inputs }:
let
  version = "1.54.2";

  src_urls = {
    aarch64-darwin = {
      url = "https://github.com/golangci/golangci-lint/releases/download/v${version}/golangci-lint-${version}-darwin-arm64.tar.gz";
      hash = "sha256-ezP7G+Lya349HzwQzpsrXObRO7HYRopLK6eU8FtEReE=";
    };
    aarch64-linux = {
      url = "https://github.com/golangci/golangci-lint/releases/download/v${version}/golangci-lint-${version}-linux-arm64.tar.gz";
      hash = "sha256-iz6MKWqXFGQZYeh0A+SGV4fxa/3Obh6jHUaXjPvbZOc=";
    };
    x86_64-darwin = {
      url = "https://github.com/golangci/golangci-lint/releases/download/v${version}/golangci-lint-${version}-darwin-amd64.tar.gz";
      hash = "sha256-klxAl+rp4DWwsFKmbQoUn4YeKrYRpOZ3x//S1OBbm4k=";
    };
    x86_64-linux = {
      url = "https://github.com/golangci/golangci-lint/releases/download/v${version}/golangci-lint-${version}-linux-amd64.tar.gz";
      hash = "sha256-F8nKBSU+/oM9R/OMr2cKrSICteZRWHmpmHP6vUx0UrM=";
    };
  };

  src = pkgs.fetchurl src_urls.${system};

  packages = rec {
    golangci-lint = pkgs.callPackage ./golangci-lint.nix { inherit src version; };
  };
in
{ inherit packages; }
