{ lib }:

with lib;

rec {
  mkSecretOption = {description ? "", default ? null}: mkOption {
    inherit description;
    type = types.nullOr (types.submodule {
      options = {
        name = mkOption {
          description = "Name of the secret where secret is stored";
          type = types.str;
        };

        key = mkOption {
          description = "Name of the key where secret is stored";
          type = types.str;
        };
      };

      config = mkDefault (if default == null then {} else default);
    });
    default = {};
  };

  secretToEnv = value: {
    valueFrom.secretKeyRef = {
      inherit (value) name key;
    };
  };

  # Creates kubernetes list from a list of kubernetes objects
  mkList = { items, labels ? {} }: {
    kind = "List";
    apiVersion = "v1";

    inherit items labels;
  };

  # Creates hashed kubernetes list from a list of kubernetes objects
  mkHashedList = { items, labels ? {} }: let
    hash = builtins.hashString "sha1" (builtins.toJSON items);

    labeledItems = map (item: recursiveUpdate item {
      metadata.labels."kubenix/hash" = hash;
    }) items;

  in mkList {
    items = labeledItems;
    labels = {
      "kubenix/hash" = hash;
    } // labels;
  };
}
