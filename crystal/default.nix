{ pkgs, system }:
let
  version = "1.8.1";
  src_urls = {
    darwin-universal = {
      url = "https://github.com/crystal-lang/crystal/releases/download/${version}/crystal-${version}-1-darwin-universal.tar.gz";
      hash = "sha256-Rnwg6pta+KPDTWFR6ZomNQmwGqeezxEgD3fb/L1KgIQ=";
    };
    linux-x86_64 = {
      url = "https://github.com/crystal-lang/crystal/releases/download/${version}/crystal-${version}-1-linux-x86_64.tar.gz";
      hash = "sha256-WRFvvk0vaE81UF95FH63LrZg1UBlOfpqigroiZAe3Gg=";
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
    rev = "a59a3dbd738269d5aad6051c3834fc70f482f469";
    hash = "sha256-t+1vM1m62UftCvfa90Dg6nqt6Zseh/GP/Gc1VfOa4+c=";
  };

  llvmPackages = pkgs.llvmPackages_15;

  packages = rec {
    crystal_prebuilt = pkgs.callPackage ./prebuilt.nix { inherit src version llvmPackages; };
    shards = pkgs.callPackage ./shards.nix { crystal = crystal_prebuilt; inherit (pkgs) fetchFromGitHub; };
    crystal = pkgs.callPackage ./crystal.nix {
      inherit crystal_prebuilt shards version llvmPackages;
      src = gh_src;
    };
    crystalWrapped = pkgs.callPackage ./extra-wrapped.nix { inherit crystal; buildInputs = [ ]; };
    crystal_dev = crystal.override { release = false; };
  };

  simple_check = given_pkg: cmd:
    pkgs.runCommand "check-${given_pkg.name}" { nativeBuildInputs = pkgs.stdenv.defaultNativeBuildInputs; } "${given_pkg}/bin/${cmd} > $out";

  checks = {
    crystal = simple_check packages.crystal "crystal eval 'puts true'";
    crystal_prebuilt = simple_check packages.crystal_prebuilt "crystal eval 'puts true'";
    shards = simple_check packages.shards "shards --version";
  };
in
if system == "aarch64-linux" then { packages = { }; checks = { }; } else { inherit packages checks; }
