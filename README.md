# Simple, recipe based flake library
aka. extensible system for cooking and sharing packages

- Use recipes (functions that produce derivations, basically any default.nix from Nixpkgs).
- Generate overlays from the recipes using lib.toOverlay
- Generate packages from the overlay
- use mkFlake to generate a default buildEnv and devShell

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.cook.url = "github:tomberek/cook";

  outputs =
    inputs:
    inputs.cook inputs {

      recipes = {

        jq = { }; # Grab jq from inputs.nixpkgs by default;

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
            name = "blah";
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
    inputs:
    inputs {

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
