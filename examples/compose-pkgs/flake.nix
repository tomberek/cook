{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.cook.url = "github:tomberek/cook";

  inputs.turbo.url = "github:tomberek/turbo";

  inputs.turbo-raw.url = "github:tomberek/turbo";
  inputs.turbo-raw.flake = false;

  outputs =
    inputs:
    inputs.cook inputs {
      recipes = {
        # bringing in a package, uses original Nixpkgs
        turbo-as-pkg = { system }: inputs.turbo.packages.${system}.turbo;

        # bring in a recipe, but use our own Nixpkgs
        tracelinks-as-recipe = inputs.turbo.recipes.tracelinks;

        # bring in a recipe without flake lock, and use our own Nixpkgs
        tracelinks-as-recipe-raw = (inputs.cook.lib.getRecipes inputs.turbo-raw).tracelinks;
      };
    };
}
