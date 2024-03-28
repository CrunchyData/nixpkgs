{ lib
, callPackage
, makeBinaryWrapper
, stdenv
, extraBuildInputs ? []
  # crystal common deps
, boehmgc
, gmp
, libevent
, libffi
, libiconv
, libxml2
, libyaml
, openssl
, pcre2
, zlib
  # expected overrides
, crystal
  # other binaries to include
, shards
}:
lib.fix (compiler:
  stdenv.mkDerivation rec {
    pname = "crystal";
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

    nativeBuildInputs = [ makeBinaryWrapper ];

    buildInputs = [ boehmgc gmp libevent libffi libxml2 libyaml openssl pcre2 zlib ]
      ++ extraBuildInputs
      ++ lib.optionals stdenv.isDarwin [ libiconv ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      ln -s ${crystal}/bin/crystal $out/bin/
      ln -s ${shards}/bin/shards $out/bin/

      wrapProgram $out/bin/crystal \
         --suffix CRYSTAL_PATH : lib:$lib/crystal \
         --suffix CRYSTAL_LIBRARY_PATH : ${ lib.makeLibraryPath (buildInputs) } \
         --suffix PKG_CONFIG_PATH : ${openssl.dev}/lib/pkgconfig \
         --suffix CRYSTAL_OPTS : "-Duse_pcre2" \

      runHook postIntsall
    '';
  }
)
