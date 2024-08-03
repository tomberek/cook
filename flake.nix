{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs =
    inputs:
    with inputs;
    {
      /*
      packages = self.lib.usingEach nixpkgs.legacyPackages (
        self.recipes
        // {
          default =
            { buildEnv, pkgs }:
            buildEnv {
              name = "default";
              paths = builtins.attrValues (self.lib.using pkgs self.recipes);
            };
        }
      );

      devShells = self.lib.usingEach nixpkgs.legacyPackages {
        default =
          { pkgs, mkShell }:
          mkShell {
            name = "shell";
            packages = builtins.attrValues (self.lib.using pkgs self.recipes);
          };
      };

      overlays.default = self.lib.toOverlay self.recipes;
      */

      /**
        Library functions
      */
      lib = rec {
        /**
          Convert recipes to an overlay
        */
        toOverlay =
          recipes: final: prev:
          builtins.mapAttrs (
            name: recipe:
            if recipe == { }
            then prev.${name}
            else if builtins.isAttrs recipe
            then
            let res = toOverlay recipe final prev;
            in  res
            else final.callPackage recipe { }
          ) recipes;

        /**
          Use a pkgset to convert recipes to packages
        */
        using =
          pkgs: recipes:
          let
            a = pkgs.lib.makeScope pkgs.newScope (final: (toOverlay recipes) final pkgs);
          in
          a.packages a;

        /**
          Alternative form of `using` for mapAttrs
        */
        usingEach = group: recipes: builtins.mapAttrs (_: pkgs: using pkgs recipes) group;

      };
    /*
    let
    in
      nixpkgs.legacyPackages = builtins.mapAttrs (_: pkgs: import pkgs.path {
        inherit system;
        config.allowUnfree = true;
      }) inputs.nixpkgs.legacyPackages;
    */
      # }}}
    };
}
