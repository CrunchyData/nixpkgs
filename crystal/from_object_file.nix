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
  version = "1.8.2";

  src = fetchurl {
    url = "https://github.com/crystal-lang/crystal/archive/refs/tags/1.8.2.tar.gz";
    hash = "sha256-bnIuMjmoxGe6QqiDiRZ4ikeVsM6qLR4umGFs7etUBgU=";
  };

  # build with
  # LLVM_CONFIG=/nix/store/dd1rhywh4b6w1w7i97mmgnz26qinn566-llvm-15.0.7-dev/bin/llvm-config make crystal -j8 target="aarch64-linux-gnu" release=true
  crystal_o = fetchurl {
    url = "https://github.com/CrunchyData/nixpkgs/releases/download/crystal-cross%2Faarch64-linux%2F1.8.2/crystal-1.8.2-aarch64-linux.tar.gz";
    hash = "sha256-s49D0Z8KDaGXOADptdGx9/hQNyFSLdNc4UhxTtiHGKc=";
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
    cc crystal.o -o crystal crystal-1.8.2/src/llvm/ext/llvm_ext.cc -lLLVM-15 -lstdc++ -lpcre2-8 -lm -lgc -lpthread -levent -lrt -lpthread -ldl
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

