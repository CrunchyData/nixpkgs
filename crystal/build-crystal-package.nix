{ stdenv
, crystal
, fetchFromGitHub
, fetchgit
, git
, installShellFiles
, lib
, linkFarm
, pkg-config
, removeReferencesTo
, which
}:

{
  # Some projects do not include a lock file, so you can pass one
  lockFile ? null
  # Generate shards.nix with `nix-shell -p crystal2nix --run crystal2nix` in the projects root
, shardsFile ? null
  # We support different builders. To make things more straight forward, make it
  # user selectable instead of trying to autodetect
, format ? "make"
, installManPages ? true
  # Specify binaries to build in the form { foo.src = "src/foo.cr"; }
  # The default `crystal build` options can be overridden with { foo.options = [ "--optionname" ]; }
, crystalBinaries ? { }
, enableParallelBuilding ? true
, gitSha ? null
, ...
}@args:

assert (builtins.elem format [ "make" "crystal" "shards" ]);
let
  mkDerivationArgs = builtins.removeAttrs args [
    "format"
    "installManPages"
    "lockFile"
    "shardsFile"
    "crystalBinaries"
  ];

  crystalLib = linkFarm "crystal-lib" (lib.mapAttrsToList
    (name: value: {
      inherit name;
      path =
        if (builtins.hasAttr "url" value)
        then fetchgit value
        else fetchFromGitHub value;
    })
    (import shardsFile));

  defaultOptions = [ "--release" "--progress" "--verbose" ];

  buildDirectly = shardsFile == null || crystalBinaries != { };

  mkCrystalBuildArgs = bin: attrs:
    lib.concatStringsSep " " ([
      "crystal"
      "build"
    ] ++ lib.optionals enableParallelBuilding [
      "--threads"
      "$NIX_BUILD_CORES"
    ] ++ [
      "-o"
      bin
      (attrs.src or (throw "No source file for crystal binary ${bin} provided"))
      (lib.concatStringsSep " " (attrs.options or defaultOptions))
    ]);

in
stdenv.mkDerivation (mkDerivationArgs // {

  configurePhase = args.configurePhase or lib.concatStringsSep "\n"
    (
      [
        "runHook preConfigure"
      ]
      ++ lib.optional (lockFile != null) "cp ${lockFile} ./shard.lock"
      ++ lib.optionals (shardsFile != null) [
        "test -e lib || mkdir lib"
        "for d in ${crystalLib}/*; do ln -s $d lib/; done"
        "cp shard.lock lib/.shards.info || true"
      ]
      ++ [ "runHook postConfigure" ]
    );

  CRFLAGS = lib.concatStringsSep " " defaultOptions;

  PREFIX = placeholder "out";

  inherit enableParallelBuilding;
  strictDeps = true;
  buildInputs = args.buildInputs or [ ] ++ [ crystal ];

  nativeBuildInputs = args.nativeBuildInputs or [ ] ++ [
    crystal
    git
    installShellFiles
    removeReferencesTo
    pkg-config
    which
  ];

  GIT_SHA = gitSha;

  buildPhase = args.buildPhase or (lib.concatStringsSep "\n" ([
    "runHook preBuild"
  ] ++ lib.optional (format == "make")
    "make \${buildTargets:-build} $makeFlags"
  ++ lib.optionals (format == "crystal") (lib.mapAttrsToList mkCrystalBuildArgs crystalBinaries)
  ++ lib.optional (format == "shards")
    "shards build --local --production ${lib.concatStringsSep " " (args.options or defaultOptions)}"
  ++ [ "runHook postBuild" ]));

  installPhase = args.installPhase or (lib.concatStringsSep "\n" ([
    "runHook preInstall"
  ] ++ lib.optional (format == "make")
    "make \${installTargets:-install} $installFlags"
  ++ lib.optionals (format == "crystal") (map
    (bin: ''
      install -Dm555 ${lib.escapeShellArgs [ bin "${placeholder "out"}/bin/${bin}" ]}
    '')
    (lib.attrNames crystalBinaries))
  ++ lib.optional (format == "shards")
    "install -Dm555 bin/* -t $out/bin"
  ++ [
    ''
      for f in README* *.md LICENSE COPYING; do
        test -f $f && install -Dm444 $f -t $out/share/doc/${args.pname}
      done
      if [ -d completions ]; then
        installShellCompletion completions/*
      fi
    ''
  ] ++ (lib.optional installManPages ''
    if [ -d man ]; then
      installManPage man/*.?
    fi
  '') ++ [
    "remove-references-to -t ${lib.getLib crystal} $out/bin/*"
    "chmod -x $out/bin/*.dwarf || true"
    "runHook postInstall"
  ]));

  doCheck = args.doCheck or true;

  checkPhase = args.checkPhase or (lib.concatStringsSep "\n" ([
    "runHook preCheck"
  ] ++ lib.optional (format == "make")
    "make \${checkTarget:-test} $checkFlags"
  ++ lib.optional (format != "make")
    "crystal \${checkTarget:-spec} $checkFlags"
  ++ [ "runHook postCheck" ]));

  doInstallCheck = args.doInstallCheck or true;

  installCheckPhase = args.installCheckPhase or ''
    for f in $out/bin/*; do
      if [[ -x $f ]]; then
        $f --help > /dev/null
      fi
    done
  '';
})


/* from nixpkgs/pkgs/development/compilers/crystal/build-package.nix

Copyright (c) 2003-2023 Eelco Dolstra and the Nixpkgs/NixOS contributors

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
