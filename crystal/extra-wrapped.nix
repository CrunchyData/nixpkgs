{ lib
, callPackage
, makeWrapper
, stdenv
  # expected overrides
, crystal
, buildInputs
}:
lib.fix (compiler:
  stdenv.mkDerivation {
    pname = "crystal-extra-wrapped";
    version = crystal.version;

    passthru = rec {
      # simple builder that sets a bunch of defaults
      mkPkg = callPackage ./common-build-args.nix { inherit buildCrystalPackage; };
      # base builder
      buildCrystalPackage = callPackage ./build-crystal-package.nix { crystal = compiler; };
    };

    dontUnpack = true;
    dontPatch = true;
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    nativeBuildInputs = [ makeWrapper ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      ln -s ${crystal}/bin/crystal $out/bin/
      ln -s ${crystal}/bin/shards $out/bin/

      wrapProgram $out/bin/crystal \
        --suffix CRYSTAL_LIBRARY_PATH : ${ lib.makeLibraryPath (buildInputs) } \

      runHook postIntsall
    '';
  }
)
