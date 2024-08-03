{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs =
    inputs: with inputs; {
      /**
        Expose mkFlake by applying the flake as a function
      */
      __functor = self: inputs.self.lib.mkFlake;

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
            if recipe == { } then
              prev.${name}
            else if builtins.isAttrs recipe then
              let
                res = toOverlay recipe final prev;
              in
              res
            else
              final.callPackage recipe { }
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

        mkFlake = inputs: flake: {
          inherit (flake) recipes;
          packages = usingEach inputs.nixpkgs.legacyPackages (
            flake.recipes
            // {
              default =
                { buildEnv, pkgs }:
                buildEnv {
                  name = "default";
                  paths = builtins.attrValues (using pkgs flake.recipes);
                };
            }
          );

          devShells = usingEach inputs.nixpkgs.legacyPackages {
            default =
              { pkgs, mkShell }:
              mkShell {
                name = "shell";
                packages = builtins.attrValues (using pkgs flake.recipes);
              };
          };

          overlays.default = toOverlay flake.recipes;
        };
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
