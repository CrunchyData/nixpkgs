{ pkgs, staticBoehmgc, system, inputs }:
let
  packages = rec {
    base = pkgs.crystal;

    crystal = pkgs.callPackage ./crystalWrapped.nix { crystal = base; };

    crystalStatic = pkgs.pkgsStatic.callPackage ./crystalWrapped.nix { crystal = base; boehmgc = staticBoehmgc; };

    inherit (pkgs) shards crystal2nix ameba;
  };

  simple_check = given_pkg: cmd:
    pkgs.runCommand "check-${given_pkg.name}" { nativeBuildInputs = pkgs.stdenv.defaultNativeBuildInputs; } "${given_pkg}/bin/${cmd} > $out";

  checks = {
    crystal = simple_check packages.crystal "crystal eval 'puts true'";
    crystalStatic = simple_check packages.crystalStatic "crystal eval 'puts true'";
    shards = simple_check packages.shards "shards --version";
    ameba = simple_check packages.ameba "ameba --help";
  };
in
{ inherit packages checks; }
