# Simple, recipe based flake library
aka. extensible system for cooking and sharing packages

- Use "recipes"
    - functions that produce derivations
    - basically any default.nix from Nixpkgs
    - `callPackage`-able things
    - no system
- Generate everything with lib.mkFlake
- Generate overlays with lib.toOverlay
- Generate packages with lib.usingEach
- Generate devShells with lib.usingEach

## Why?
- Composing a flake can be intimidating:
    - systems
    - callPackage
    - overlays
- flake users tend to define and expose packages.SYSTEM.name
  which is harder to reuse with new systems or cross-compile
- use the same concept that people will encounter in a Nixpkgs `default.nix`

# Examples

## Putting recipes into default.nix
```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.cook.url = "github:tomberek/cook";

  outputs =
    inputs:
    inputs.cook inputs {
      recipes.my-custom = ./pkgs/custom/;
      recipes.my-custom = ./pkgs/custom-2/default.nix;
    };
}
```


## Custom inline packages
```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.cook.url = "github:tomberek/cook";

  outputs =
    inputs:
    inputs.cook inputs {

      recipes = {

        my-custom-package =
          { runCommand }:
          runCommand "thing" { } ''
            mkdir -p $out/bin
            cat > $out/bin/thing <<EOF
            #!/bin/sh
            echo custom package
            EOF
            chmod +x $out/bin/thing
          '';

        my-other-package =
          { stdenv, gnutar }:
          stdenv.mkDerivation {
            name = "hello";
            src = inputs.nixpkgs.legacyPackages.x86_64-linux.hello.src;
            buildCommand = ''
              set -x
              ${gnutar}/bin/tar -xf $src
              cd hello*
              ./configure --prefix=$out
              make
              make install
            '';
          };
      };
    };
}
```

## Composition
Recipes from another flake don't depend on the Nixpkgs in the other flake,
making it easier to avoid having binaries from multiple Nixpkgs in a runtime closure.
```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.cook.url = "github:tomberek/cook";

  inputs.my-other-flake.url = "github:ORG/REPO";

  outputs =
    inputs:
    inputs.cook inputs {

      recipes = inputs.my-other-flake.recipes // {
        my-custom = ./pkgs/custom-2/default.nix;
      };

    };
}
```


## Manually using the API
```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.cook.url = "github:tomberek/cook";

  outputs =
    inputs: with inputs; {

      recipes.packages.jq = { };

      recipes.devShells.default = {mkShell,pkgs}: mkShell {
        name = "shell";
        packages = builtins.attrValues (cook.lib.using pkgs self.recipes.packages);
      };

      overlays.default = cook.lib.toOverlay self.recipes.packages;
      packages = cook.lib.usingEach nixpkgs.legacyPackages self.recipes.packages;
      devShells = cook.lib.usingEach nixpkgs.legacyPackages self.recipes.devShells;
    };
}
```

## Abusing `__functor`
```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.__functor.url = "github:tomberek/cook";

  outputs =
    _:
    _ {

      recipes.jq = { };
      recipes.hello = { };

    };
}
```


# Example to use nixpkgs with unfree.
```nix
      nixpkgs.legacyPackages = builtins.mapAttrs (_: pkgs: import pkgs.path {
        inherit system;
        config.allowUnfree = true;
      }) inputs.nixpkgs.legacyPackages;
```

# Questions
- should it be just recipes or recipes.packages+recipes.devShells?
