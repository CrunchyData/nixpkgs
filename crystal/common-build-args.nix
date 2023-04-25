{ buildCrystalPackage }:
let
  fn = { src, self, ... }@args:
    let
      shardValue = import ./shard-value.nix { inherit src; };
      pkgArgs = {
        pname = shardValue "name";
        version = shardValue "version";
        format = "shards";
        lockFile = src + /shard.lock;
        shardsFile = src + /shards.nix;
        gitSha = self.shortRev or "dirty";
      } // args;
    in
    buildCrystalPackage pkgArgs;
in
fn
