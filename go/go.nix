{ stdenv, src, version }:
stdenv.mkDerivation rec {
  pname = "go";
  inherit src version;
  inherit (stdenv) isDarwin;

  outputs = [ "out" ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    export GOROOT=$out
    cp -a bin pkg src lib misc api doc go.env $GOROOT
    ln -s $GOROOT/bin $out/bin
    runHook postInstall
  '';

  dontStrip = true;
}
