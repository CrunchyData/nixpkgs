{ src }:
key: builtins.head (builtins.match (".*" + key + ": ([-a-zA-Z0-9\.]+).*") (builtins.readFile (src + "/shard.yml")))
