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
