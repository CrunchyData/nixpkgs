{
  description = "A very basic flake";

  outputs = { self, nixpkgs }:
  let
    utils = import ../lib/utils.nix;
  in
    utils.eachDefaultSystem (system:
    let
    arch = {
      x86_64-darwin = "darwin-amd64";
      aarch64-darwin = "darwin-arm64";
      x86_64-linux = "linux-amd64";
      aarch64-linux = "linux-arm64";
    }.${system};

    version = "1.52.2";

    pkgs = import nixpkgs { inherit system; };

    in {
      packages = rec {
        golangci-lint = pkgs.stdenv.mkDerivation {
          name = "golangci-lint";

          src = builtins.fetchTarball {
            url = "https://github.com/golangci/golangci-lint/releases/download/v${version}/golangci-lint-${version}-${arch}.tar.gz";
            sha256 = "sha256:04jhb6ss6npkd7hjah7h8xq7akdkk2r8mgbzdisbixcnk8q20k2n";
          };

          installPhase = ''
            mkdir -p $out/bin
            install golangci-lint $out/bin
          '';

          postInstall = ''
          for shell in bash fish zsh; do
            HOME=$TMPDIR $out/bin/golangci-lint completion $shell > golangci-lint.$shell
            installShellCompletion golangci-lint.$shell
          done
          '';
        };

        default = golangci-lint;
      };
    });
}
