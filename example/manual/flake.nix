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
