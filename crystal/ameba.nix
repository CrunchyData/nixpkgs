{ crystal, src }:
let
  parsedShard = (import ./lib.nix).parseShard src;
in
crystal.buildCrystalPackage {
  inherit src;
  inherit (parsedShard) pname version;
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
