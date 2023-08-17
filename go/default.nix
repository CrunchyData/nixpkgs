{ pkgs, system, inputs }:
let
  version = "1.21.0";

  src_urls = {
    aarch64-darwin = {
      url = "https://go.dev/dl/go${version}.darwin-arm64.tar.gz";
      hash = "sha256-OspE3lXF4JjeL0BumKujKImLBdUJouKjVkFvqs8sRWY=";
    };
    aarch64-linux = {
      url = "https://go.dev/dl/go${version}.linux-arm64.tar.gz";
      hash = "sha256-89RUjt+bIvJrvUlyA1C7/lnXW3CQoaK/8a+tghT+uvM=";
    };
    x86_64-darwin = {
      url = "https://go.dev/dl/go${version}.darwin-amd64.tar.gz";
      hash = "sha256-sxTen3BKsSLAd9LsjmfjZwr/6IZUedHwGZHnrFXWXnA=";
    };
    x86_64-linux = {
      url = "https://go.dev/dl/go${version}.linux-amd64.tar.gz";
      hash = "sha256-0DmJA6FroiMrOJ+zEDLd9XysNO/aMGoO66w08JZaB0I=";
    };
  };

  src = pkgs.fetchurl src_urls.${system};

  packages = rec {
    go = pkgs.callPackage ./go.nix { inherit src version; };
  };
in
{ inherit packages; }
