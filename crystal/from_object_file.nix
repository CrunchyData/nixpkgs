{ stdenv
, lib
, pkg-config
, which
, installShellFiles
, makeWrapper
, fetchurl
  # crystal deps
, clang_15
, llvm_15
, boehmgc
, gmp
, libevent
, libxml2
, libyaml
, openssl
, pcre2
, zlib
}:
stdenv.mkDerivation rec {
  pname = "crystal";
  version = "1.11.2";

  src = fetchurl {
    url = "https://github.com/crystal-lang/crystal/archive/refs/tags/${version}.tar.gz";
    hash = "sha256-l0Dw9SdF05lEmxGmSwYCFshZnvc3EmFf6JVqHo98XZw=";
  };

  # Install make and a Crystal compiler and then in the Crystal source directory build with:
  #
  # LLVM_CONFIG=/nix/store/dar7mwpqglsa91qdh2m4is8yhcxmwfrc-llvm-17.0.6-dev/bin/llvm-config make crystal -j8 target="aarch64-linux-gnu" release=true
  crystal_o = fetchurl {
    url = "https://github.com/CrunchyData/nixpkgs/releases/download/crystal-cross%2Faarch64-linux%2F1.11.1/crystal-1.11.1-aarch64-linux.tar.gz";
    hash = "sha256-i9UsVNu8jHNfLODpDW2KPywUf5hZ6ru1NN09AQayWlY=";
  };

  nativeBuildInputs = [ makeWrapper installShellFiles ];
  buildInputs = [
    llvm_15
    boehmgc
    gmp
    libevent
    libxml2
    libyaml
    openssl
    pcre2
    zlib
  ];

  buildPhase = ''
    tar xvf ${crystal_o}
    tar xvf ${src}
    cc crystal.o -o crystal crystal-${version}/src/llvm/ext/llvm_ext.cc -lLLVM-17 -lstdc++ -lpcre2-8 -lm -lgc -lpthread -levent -lrt -lpthread -ldl
  '';

  enableParallelBuilding = true;

  outputs = [ "out" "lib" "bin" ];

  installPhase = ''
    install -Dm755 crystal $bin/bin/crystal

    wrapProgram $bin/bin/crystal \
   --prefix PATH : ${lib.makeBinPath [ clang_15 ] } \
   --suffix PATH : ${lib.makeBinPath [ pkg-config which ]} \
   --suffix CRYSTAL_PATH : lib:$lib/crystal \
   --suffix CRYSTAL_LIBRARY_PATH : ${ lib.makeLibraryPath (buildInputs) } \
   --suffix PKG_CONFIG_PATH : ${openssl.dev}/lib/pkgconfig \
   --suffix CRYSTAL_OPTS : "-Duse_pcre2" \

    install -dm755 $lib/crystal

    cp -r src/* $lib/crystal/

    mkdir -p $out
    ln -s $bin/bin $out/bin
    ln -s $lib $out/lib
  '';
}

