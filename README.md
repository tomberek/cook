# Simple, recipe based flake library

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.cook.url = "github:tomberek/cook";

  outputs =
    inputs:
    inputs.cook.lib.mkFlake inputs {

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
