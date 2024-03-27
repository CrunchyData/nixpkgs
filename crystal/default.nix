{ pkgs, staticBoehmgc, system, inputs }:
let

  # NOTE: currently (2023-11-29) `nix flake check` fails on x86 macs due to
  #    error: don't yet have a `targetPackages.darwin.LibsystemCross for x86_64-apple-darwin`
  # so only have a static package on the other platforms for now.
  # some maybe relevant issues:
  # https://github.com/NixOS/nixpkgs/pull/256590
  # https://github.com/NixOS/nixpkgs/issues/180771
  # https://github.com/NixOS/nixpkgs/issues/270375
  crystalStatic = if system == "x86_64-darwin" then null else "crystalStatic";

  packages = rec {
    inherit (pkgs) shards crystal2nix ameba;

    base = pkgs.crystal;

    crystal = pkgs.callPackage ./crystalWrapped.nix { crystal = base; };
    ${crystalStatic} = pkgs.pkgsStatic.callPackage ./crystalWrapped.nix { crystal = base; boehmgc = staticBoehmgc; };
  };

  simple_check = given_pkg: cmd:
    pkgs.runCommand "check-${given_pkg.name}" { nativeBuildInputs = pkgs.stdenv.defaultNativeBuildInputs; } "${given_pkg}/bin/${cmd} > $out";

  checks = {
    crystal = simple_check packages.crystal "crystal eval 'puts true'";
    # crystalStatic = simple_check packages.crystalStatic "crystal eval 'puts true'"; # FIXME: static builds not working on linux
    shards = simple_check packages.shards "shards --version";
    ameba = simple_check packages.ameba "ameba --help";
  };
in
{ inherit packages checks; }
