# only parts of https://github.com/numtide/flake-utils/blob/master/default.nix that we use

let
  # The list of systems supported by nixpkgs and hydra
  defaultSystems = [
    "aarch64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
    "x86_64-linux"
  ];

  # A map from system to system. It's useful to detect typos.
  #
  # Instead of typing `"x86_64-linux"`, type `flake-utils.lib.system.x86_64-linux`
  # and get an error back if you used a dash instead of an underscore.
  system =
    builtins.listToAttrs
      (map (system: { name = system; value = system; }) defaultSystems);

 # eachSystem using defaultSystems
  eachDefaultSystem = eachSystem defaultSystems;



  # Builds a map from <attr>=value to <attr>.<system>=value for each system,
  # except for the `hydraJobs` attribute, where it maps the inner attributes,
  # from hydraJobs.<attr>=value to hydraJobs.<attr>.<system>=value.
  #
  eachSystem = systems: f:
    let
      # Taken from <nixpkgs/lib/attrsets.nix>
      isDerivation = x: builtins.isAttrs x && x ? type && x.type == "derivation";

      # Used to match Hydra's convention of how to define jobs. Basically transforms
      #
      #     hydraJobs = {
      #       hello = <derivation>;
      #       haskellPackages.aeson = <derivation>;
      #     }
      #
      # to
      #
      #     hydraJobs = {
      #       hello.x86_64-linux = <derivation>;
      #       haskellPackages.aeson.x86_64-linux = <derivation>;
      #     }
      #
      # if the given flake does `eachSystem [ "x86_64-linux" ] { ... }`.
      pushDownSystem = system: merged:
        builtins.mapAttrs
          (name: value:
            if ! (builtins.isAttrs value) then value
            else if isDerivation value then (merged.${name} or {}) // { ${system} = value; }
            else pushDownSystem system (merged.${name} or {}) value);

      # Merge together the outputs for all systems.
      op = attrs: system:
        let
          ret = f system;
          op = attrs: key:
            let
              appendSystem = key: system: ret:
                if key == "hydraJobs"
                  then (pushDownSystem system (attrs.hydraJobs or {}) ret.hydraJobs)
                  else { ${system} = ret.${key}; };
            in attrs //
              {
                ${key} = (attrs.${key} or { })
                  // (appendSystem key system ret);
              }
          ;
        in
        builtins.foldl' op attrs (builtins.attrNames ret);
    in
    builtins.foldl' op { } systems
  ;

  lib = {
    inherit
      eachDefaultSystem
      system
      ;
  };
in
lib


# MIT License
#
# Copyright (c) 2020 zimbatm
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.