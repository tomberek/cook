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
