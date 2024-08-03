# Simple, recipe based flake library

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.cook.url = "github:tomberek/cook";

  outputs =
    {
      self,
      nixpkgs,
      cook,
      ...
    }:
    {

      recipes = {
        hello = { };
        jq = { };

        my-custom-package =
          { runCommand }:
          runCommand "thing" { } ''
            mkdir $out
            echo something > $out/somewhere
          '';

        my-other-package =
          { stdenv }:
          stdenv.mkDerivation {
            name = "blah";
            src = ./.;
            buildCommand = ''
              mkdir $out
              echo something > $out/somewhere
            '';
          };
      };

      packages = cook.lib.usingEach nixpkgs.legacyPackages self.recipes;
      devShells = cook.lib.usingEach nixpkgs.legacyPackages {
        default =
          { pkgs, mkShell }:
          mkShell {
            name = "shell";
            packages = builtins.attrValues (cook.lib.using pkgs self.recipes);
          };
      };
      overlays.default = cook.lib.toOverlay self.recipes;
    };
}
```


# Example to use nixpkgs with unfree.
```
      nixpkgs.legacyPackages = builtins.mapAttrs (_: pkgs: import pkgs.path {
        inherit system;
        config.allowUnfree = true;
      }) inputs.nixpkgs.legacyPackages;
```
