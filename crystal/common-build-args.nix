{ buildCrystalPackage }:
let
  fn = { src, ... }@args:
    let
      lib = import ./lib.nix;
      parsedShard = lib.parseShard src;
      pkgArgs = {
        inherit (parsedShard) pname version;
        format = "shards";
        lockFile = src + "/shard.lock";
        shardsFile = src + "/shards.nix";
        gitSha = args.self.shortRev or "dirty";
      } // args;
    in
    buildCrystalPackage pkgArgs;
in
fn
