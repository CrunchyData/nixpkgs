{ pkgs, system, inputs }:
let
  version = "1.11.2";
  src_urls = {
    darwin-universal = {
      url = "https://github.com/crystal-lang/crystal/releases/download/${version}/crystal-${version}-1-darwin-universal.tar.gz";
      hash = "sha256-ejbozz2CZO9s0XVu5XY0N0qLOc2IMYlv3qAIjgR4tOQ=";
    };
    linux-x86_64 = {
      url = "https://github.com/crystal-lang/crystal/releases/download/${version}/crystal-${version}-1-linux-x86_64.tar.gz";
      hash = "sha256-cy7qnfZFjIkVfa6UX7CtvuC+tjRcoDvDzNKZsr8Iea4=";
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

    base = pkgs.callPackage ./crystal.nix {
      inherit crystal_prebuilt shards llvmPackages;
      src = inputs.crystal-src;
    };
    base_dev = base.override { release = false; };

    crystal = pkgs.callPackage ./crystalWrapped.nix { crystal = base; };
    crystal_dev = pkgs.callPackage ./crystalWrapped.nix { crystal = base_dev; };
    crystalStatic = pkgs.pkgsStatic.callPackage ./crystalWrapped.nix { crystal = base; };
    crystalStatic_dev = pkgs.pkgsStatic.callPackage ./crystalWrapped.nix { crystal = base_dev; };

    shards = pkgs.callPackage ./shards.nix { crystal = crystal_prebuilt; inherit (pkgs) fetchFromGitHub; };
    crystal2nix = pkgs.crystal2nix.override { inherit crystal; };
    ameba = pkgs.callPackage ./ameba.nix { inherit crystal; src = inputs.ameba-src; };
  };

  eval_check = given_pkg: cmd:
    pkgs.runCommand "check-${given_pkg.name}"
    { nativeBuildInputs = pkgs.stdenv.defaultNativeBuildInputs; }
    "${given_pkg}/bin/${cmd} > $out";

  static_build_check = given_pkg:
    pkgs.runCommand
      "check-${given_pkg.name}"
      { nativeBuildInputs = pkgs.pkgsStatic.stdenv.defaultNativeBuildInputs; }
      "echo puts true > check.cr && ${given_pkg}/bin/crystal build --static check.cr > $out && ./check";

  checks = {
    crystal = eval_check packages.crystal "crystal eval 'puts true'";
    crystalStatic = static_build_check packages.crystalStatic;
    crystal_prebuilt = eval_check packages.crystal_prebuilt "crystal eval 'puts true'";
    shards = eval_check packages.shards "shards --version";
    crystal2nix = packages.crystal2nix; # -h errors out if there is no shards.nix file, so just use the package itself as a check
    ameba = eval_check packages.ameba "ameba --help";
  };
in
{ inherit packages checks; }
