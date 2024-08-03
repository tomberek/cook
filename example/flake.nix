{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.simple.url = "github:tomberek/simple";

  outputs =
    {
      self,
      nixpkgs,
      simple,
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

      packages = simple.lib.usingEach nixpkgs.legacyPackages self.recipes;
      devShells = simple.lib.usingEach nixpkgs.legacyPackages {
        default =
          { pkgs, mkShell }:
          mkShell {
            name = "shell";
            packages = builtins.attrValues (simple.lib.using pkgs self.recipes);
          };
      };
      overlays.default = simple.lib.toOverlay self.recipes;
    };
}
