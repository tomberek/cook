{
  outputs =
    { self, ... }: rec {
      using =
        pkgs: recipes:
        let
          result = builtins.mapAttrs (
            name: recipe:
            if recipe == {} then pkgs.${name} else
            pkgs.lib.callPackageWith (pkgs // result) recipe { }
          ) recipes;
        in
        result;
      usingFor = pkgGroup: recipes: builtins.mapAttrs (_: pkgs: using pkgs recipes) pkgGroup;
    };
}
