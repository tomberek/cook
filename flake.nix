{
  outputs = inputs: {
    /**
      Expose mkFlake by applying the flake as a function
    */
    __functor = self: inputs.self.lib.mkFlake;

    /**
      Library functions
    */
    lib = rec {
      /**
          toOverlay :: recipes -> overlay
          Convert recipes to an overlay
      */
      toOverlay =
        name: recipes: final: prev:
        let
          newScope = prev.xorg or { } // prev // final;
          makeScope' = prev.lib.makeScope (scope: prev.lib.callPackageWith (newScope // scope));
        in
        if recipes == { } then
          prev.${name}
        else if name == "python3Packages" then
          (makeScope' (
            scope:
            prev.python3.override (old: {
              packageOverrides = pyfinal: pyprev: toOverlay "" recipes (final // pyfinal // scope) pyprev;
            })
          )).pkgs
          // {
            packages = self: builtins.intersectAttrs recipes self;
          }
        else if builtins.isAttrs recipes && !recipes ? __functor then
          makeScope' (
            scope:
            builtins.mapAttrs (
              n: recipe: toOverlay n recipe (final // scope) (prev // prev.${name} or { })
            ) recipes
          )
        else
          final.callPackage recipes (
            builtins.intersectAttrs (builtins.functionArgs recipes) {
              ${name} = prev.${name} or (throw "cannot find ${name} in base");
            }
          );
      /**
        using :: packageSet -> recipes -> packages
        Use a pkgset to convert recipes to packages
      */
      using =
        pkgs: recipes:
        let
          lib = pkgs.lib;
          mkNested =
            { pkgset, recipes }:
            if !lib.isFunction recipes && lib.isFunction (pkgset.packages or null) then
              builtins.mapAttrs (
                n: s:
                mkNested {
                  pkgset = s;
                  recipes = recipes.${n} or (_: _);
                }
              ) (pkgset.packages pkgset)
            else
              pkgset;
        in
        mkNested {
          # = toOverlay "__root" recipes a pkgs;
          pkgset = pkgs.extend (toOverlay "__root" recipes);
          recipes = recipes;
        };

      /**
        usingEach :: SYSTEM.packageSet -> recipes -> SYSTEM.packageSet
        Alternative form of `using` for mapAttrs
      */
      usingEach = group: recipes: builtins.mapAttrs (_: pkgs: using pkgs recipes) group;

      /**
        mkFlake :: inputs -> flakeArgs -> flakeOutputs
        Helper function to make a flake from recipes.
        Creates a set of overlays.
        Creates a default buildEnv package and devShell as well.
      */
      mkFlake = inputs: flake: {
        inherit (flake) recipes;
        packages = usingEach inputs.nixpkgs.legacyPackages (
          {
            default =
              {
                buildEnv,
                pkgs,
                lib,
              }:
              buildEnv {
                name = "default";
                paths = lib.collect lib.isDerivation (using pkgs flake.recipes);
              };
          }
          // flake.recipes or { }
        );
        devShells = usingEach inputs.nixpkgs.legacyPackages (
          {
            default =
              {
                pkgs,
                mkShell,
                lib,
              }:
              mkShell {
                name = "shell";
                packages = lib.collect lib.isDerivation (using pkgs flake.recipes);
              };
          }
          // flake.recipes.devShells or { }
        );
        overlays.default = toOverlay flake.recipes;
      };

      # Enforces a "simple lockless-recipes", no subflakes for inheritance, narHash causes topdir to load
      getRecipes =
        flake:
        (builtins.getFlake (
          builtins.unsafeDiscardStringContext "path://${flake.outPath}?narHash=${flake.narHash}"
        )).recipes or flake.recipes;
    };
  };
}
