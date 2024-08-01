{
  outputs =
    { self, ... }:
    rec {
      withConfig = config: nixpkgs: {
        legacyPackages = builtins.mapAttrs (
          system: pkgs: import nixpkgs ({ inherit system; } // config)
        ) nixpkgs.legacyPackages;
      };
      using =
        pkgs: recipes:
        let
          result = builtins.mapAttrs (
            name: recipe:
            if recipe == { } then pkgs.${name} else pkgs.lib.callPackageWith (pkgs // result) recipe { }
          ) recipes;
        in
        result;

      usingFor = pkgGroup: recipes: builtins.mapAttrs (_: pkgs: using pkgs recipes) pkgGroup;

      usingPkgs =
        pkgGroup: recipes:
        usingFor pkgGroup (
          recipes
          // {
            default =
              { buildEnv, pkgs }:
              buildEnv {
                name = "default-env";
                paths = builtins.attrValues (using pkgs recipes);
              };
          }
        );

      usingShells =
        pkgGroup: recipes:
        usingFor pkgGroup (
          recipes
          // {
            default =
              { mkShell, pkgs }:
              mkShell {
                name = "default-shell";
                packages = builtins.attrValues (using pkgs recipes);
              };
          }
        );

      usingOverlays =
        recipes: self: super:
        builtins.mapAttrs (name: recipe: self.callPackage recipe { }) recipes;

    };
}
