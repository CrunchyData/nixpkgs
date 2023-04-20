{ stdenv
, fetchFromGitHub
, lib
  # build deps
, crystal
  # install deps
, installShellFiles
, makeWrapper
  # shards runtime deps
, boehmgc
, libevent
, libiconv
, libyaml
, pcre2
}:
stdenv.mkDerivation rec {
  pname = "shards";
  version = "0.17.3";
  src = fetchFromGitHub {
    owner = "crystal-lang";
    repo = "shards";
    rev = "v${version}";
    hash = "sha256-vgcMB/vp685YwYI9XtJ5cTEjdnYaZY9aOMUnJBJaQoU=";
  };
  dep_molinillo = fetchFromGitHub {
    owner = "crystal-lang";
    repo = "crystal-molinillo";
    rev = "v0.2.0";
    hash = "sha256-0PIP39pO6TgLyA0l/1CumQGM8RQKrjnm+wNYmddF8V8=";
  };

  nativeBuildInputs = [ crystal makeWrapper installShellFiles ];

  buildInputs = [
    boehmgc
    libevent
    libyaml
    pcre2
  ] ++ lib.optionals stdenv.isDarwin [ libiconv ];

  buildPhase = ''
    mkdir lib
    cp -R ${dep_molinillo} lib/molinillo
    crystal build src/shards.cr
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    mv shards $out/bin/shards
    runHook postInstall
  '';
}
