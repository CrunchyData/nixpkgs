{ buildCrystalPackage }:
let
  fn = { src, self, ... }@args:
    let
      shardValue = key: builtins.head (builtins.match (".*" + key + ": ([-a-zA-Z0-9\.]+).*") (builtins.readFile (src + /shard.yml)));
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
