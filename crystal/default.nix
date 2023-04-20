{ pkgs, system }:
let
  version = "1.8.0";
  src_urls = {
    darwin-universal = {
      url = "https://github.com/crystal-lang/crystal/releases/download/${version}/crystal-${version}-1-darwin-universal.tar.gz";
      hash = "sha256-CKbciHPOU68bpgMEWhRf7+I/gDxrraorTX4CxmbTQtA=";
    };
    linux-x86_64 = {
      url = "https://github.com/crystal-lang/crystal/releases/download/${version}/crystal-${version}-1-linux-x86_64.tar.gz";
      hash = "sha256-AAsbMB/IH8cGpndYIEwgHLYgwQj6CzLZfrEmXdf5QXc=";
    };
  };

  archs = {
    x86_64-darwin = "darwin-universal";
    aarch64-darwin = "darwin-universal";
    x86_64-linux = "linux-x86_64";
  };
  arch = archs.${system};
  src = pkgs.fetchurl src_urls.${arch};

  gh_src = pkgs.fetchFromGitHub {
    owner = "crystal-lang";
    repo = "crystal";
    rev = version;
    hash = "sha256-L1SUeuifXBlwyL60an2ndsAuLhZ3RMBKxYrKygzVBI8";
  };

  llvmPackages = pkgs.llvmPackages_15;

  packages = rec {
    crystal_prebuilt = pkgs.callPackage ./prebuilt.nix { inherit src version llvmPackages; };
    shards = pkgs.callPackage ./shards.nix { crystal = crystal_prebuilt; inherit (pkgs) fetchFromGitHub; };
    crystal = pkgs.callPackage ./crystal.nix {
      inherit crystal_prebuilt shards version llvmPackages;
      src = gh_src;
    };
    extraWrapped = pkgs.callPackage ./extra-wrapped.nix { inherit crystal; buildInputs = [ ]; };
    crystal_dev = crystal.override { release = false; };
  };
in
if system == "aarch64-linux" then { } else packages
