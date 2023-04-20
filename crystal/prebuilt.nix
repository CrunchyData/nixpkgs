{ stdenv
, lib
, src
, substituteAll
, version
  # install deps
, installShellFiles
, makeWrapper
, which
  # crystal common deps
, boehmgc
, gmp
, libevent
, libiconv
, libxml2
, libyaml
, llvmPackages
, openssl
, pcre2
, pkg-config
, tzdata
, zlib
}:
stdenv.mkDerivation rec {
  pname = "crystal";
  inherit src version;
  inherit (stdenv) isDarwin;

  nativeBuildInputs = [ makeWrapper installShellFiles ];

  strictDeps = true;
  outputs = [ "out" "lib" "bin" ];

  buildInputs = [
    boehmgc
    gmp
    libevent
    libxml2
    libyaml
    openssl
    pcre2
    zlib
  ] ++ lib.optionals isDarwin [ libiconv ];

  prePatch = lib.optionals stdenv.isLinux ''
    mv share/crystal/src .
  '';

  patches = [
    (substituteAll {
      src = ./tzdata.patch;
      inherit tzdata;
    })
  ];

  dontConfigure = true;
  dontBuild = true;

  tarball_bin = if isDarwin then "./embedded/bin" else "./bin";
  completion =
    if isDarwin then ''
      installShellCompletion --cmd crystal etc/completion.*
    '' else ''
      installShellCompletion --bash share/bash-completion/completions/crystal
      installShellCompletion --zsh share/zsh/site-functions/_crystal
      installShellCompletion --fish share/fish/vendor_completions.d/crystal.fish
    '';

  installPhase = ''
    runHook preInstall

    install -Dm755 ${tarball_bin}/shards $bin/bin/shards
    install -Dm755 ${tarball_bin}/crystal $bin/bin/crystal
    wrapProgram $bin/bin/crystal \
       --suffix PATH : ${lib.makeBinPath [ pkg-config llvmPackages.clang which ]} \
       --suffix CRYSTAL_PATH : lib:$lib/crystal \
       --suffix CRYSTAL_LIBRARY_PATH : ${ lib.makeLibraryPath (buildInputs) } \
       --suffix PKG_CONFIG_PATH : ${openssl.dev}/lib/pkgconfig \
       --suffix CRYSTAL_OPTS : "-Duse_pcre2"

    install -dm755 $lib/crystal
    cp -r src/* $lib/crystal/

    ${completion}

    mkdir -p $out
    ln -s $bin/bin $out/bin
    ln -s $lib $out/lib

    runHook postInstall
  '';

  dontStrip = true;
}
