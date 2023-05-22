{ pkgs, system, inputs }:
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

  llvmPackages = pkgs.llvmPackages_15;

  packages = rec {
    crystal_prebuilt =
      if system == "aarch64-linux" then
        pkgs.callPackage ./from_object_file.nix {} # not really prebuilt until they make official aarch64-linux builds
      else
        pkgs.callPackage ./prebuilt.nix { inherit src version llvmPackages; };

    shards = pkgs.callPackage ./shards.nix { crystal = crystal_prebuilt; inherit (pkgs) fetchFromGitHub; };
    crystal = pkgs.callPackage ./crystal.nix {
      inherit crystal_prebuilt shards llvmPackages;
      src = inputs.crystal-src;
    };
    crystalWrapped = pkgs.callPackage ./extra-wrapped.nix { inherit crystal; buildInputs = [ ]; };
    crystal_dev = crystal.override { release = false; };
    crystal2nix = pkgs.crystal2nix.override { inherit crystal; };
    ameba = pkgs.callPackage ./ameba.nix { inherit crystal; src = inputs.ameba-src; };
  };

  simple_check = given_pkg: cmd:
    pkgs.runCommand "check-${given_pkg.name}" { nativeBuildInputs = pkgs.stdenv.defaultNativeBuildInputs; } "${given_pkg}/bin/${cmd} > $out";

  checks = {
    crystal = simple_check packages.crystal "crystal eval 'puts true'";
    crystal_prebuilt = simple_check packages.crystal_prebuilt "crystal eval 'puts true'";
    shards = simple_check packages.shards "shards --version";
    crystal2nix = packages.crystal2nix; # -h errors out if there is no shards.nix file, so just use the package itself as a check
    ameba = simple_check packages.ameba "ameba --help";
  };
in
{ inherit packages checks; }
