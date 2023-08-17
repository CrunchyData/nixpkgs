{ stdenv, src, version}:
stdenv.mkDerivation rec {
  pname = "golangci-lint";
  inherit src version;
  inherit (stdenv) isDarwin;

  outputs = [ "out" ];
  dontConfigure = true;
  dontBuild = true;

   installPhase = ''
    mkdir -p $out/bin
    install -t $out/bin golangci-lint
  '';

  dontStrip = true;
}
