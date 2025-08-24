{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gitignore = {
    url = "github:hercules-ci/gitignore.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.haskellNix.url = "github:input-output-hk/haskell.nix/master";
  inputs.nixpkgs.follows = "haskellNix";

  outputs = { self, flake-utils, gitignore, haskellNix, nixpkgs }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (system:
      let
        compiler-nix-name = "ghc9122";

        overlays = [
          haskellNix.overlay

          # Configure hixProject
          (final: prev: {
            hixProject = compiler-nix-name:
              final.haskell-nix.hix.project {
                src = gitignore.lib.gitignoreSource ./.;
                evalSystem = system;
                inherit compiler-nix-name;

                modules = [{
                  packages.ghc912-repro.components.exes.ghc912-repro.dontStrip = false;
                }];
              };
          })
        ];

        pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };

      in
        {
          devShells = {
            default = pkgs.mkShell {
              buildInputs = [];
            };
          };

          packages = ({
            normal = ((pkgs.hixProject compiler-nix-name).flake {}).packages."ghc912-repro:exe:ghc912-repro";
            musl64 = ((pkgs.pkgsCross.musl64.hixProject compiler-nix-name).flake {}).packages."ghc912-repro:exe:ghc912-repro";
            aarch64-multiplatform = ((pkgs.pkgsCross.aarch64-multiplatform.hixProject compiler-nix-name).flake {}).packages."ghc912-repro:exe:ghc912-repro";
            aarch64-multiplatform-musl = ((pkgs.pkgsCross.aarch64-multiplatform-musl.hixProject compiler-nix-name).flake {}).packages."ghc912-repro:exe:ghc912-repro";

            hackage = (pkgs.pkgsCross.aarch64-multiplatform-musl.haskell-nix.hackage-package { compiler-nix-name = "ghc9122"; name = "pandoc-types"; }).components.library;
          });
        }
    );

  # nixConfig = {
  #   # This sets the flake to use the IOG nix cache.
  #   # Nix should ask for permission before using it,
  #   # but remove it here if you do not want it to.
  #   extra-substituters = ["https://cache.iog.io"];
  #   extra-trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
  #   allow-import-from-derivation = "true";
  # };
}
