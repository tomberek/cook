{
  inputs.cook.url = "github:tomberek/cook";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    _:
    _.cook.lib.mkFlake
      {
        nixpkgs.legacyPackages = builtins.mapAttrs (
          system: pkgs:
          import pkgs.path {
            inherit system;
            config.allowUnfree = true;
          }
        ) _.nixpkgs.legacyPackages;
      }
      {
        recipes.hello-unfree = { };
      };
}
