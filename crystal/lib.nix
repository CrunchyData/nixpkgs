let
  lib.parseShard = src:
    let sv = lib.shardValue src;
    in { pname = sv "name"; version = sv "version"; };

  # returns a function that can read a value for a key in shard.yml
  lib.shardValue = src: key:
    let
      file = src + "/shard.yml";
      contents = builtins.readFile file;
      match = builtins.split (key + ": ([-a-zA-Z0-9\.]+).*\n") contents;
    in
      if builtins.length match == 3 then
        builtins.head (builtins.head (builtins.tail match))
      else
       builtins.traceVerbose "file ${file} doesn't have top-level key '${key}'" null;
in
lib
