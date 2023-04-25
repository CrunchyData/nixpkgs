{ crystal, src }:
let
  shardValue = import ./shard-value.nix { inherit src; };
in
crystal.buildCrystalPackage {
  inherit src;
  pname = "ameba";
  version = shardValue "version";
  doCheck = false;
  format = "crystal";
  crystalBinaries.ameba = {
    src = "bin/ameba.cr";
    options = [ "-Dpreview_mt" "--release" "--progress" "--verbose" "--no-debug" ];
  };
  preBuild = ''
    mkdir -p lib
    ln -s $src lib/ameba
  '';
}
