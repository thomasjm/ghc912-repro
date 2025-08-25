{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gitignore = {
    url = "github:hercules-ci/gitignore.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.haskellNix.url = "github:input-output-hk/haskell.nix/master";
  inputs.nixpkgs.follows = "haskellNix/nixpkgs";

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
                  reinstallableLibGhc = false;
                  nonReinstallablePkgs = [
                    "ghc" "ghc-boot" "rts" "Cabal-syntax" "Cabal" "Win32" "array" "base" "binary" "bytestring" "containers" "deepseq" "directory" "exceptions" "file-io" "filepath" "ghc-boot-th" "ghc-compact" "ghc-experimental" "ghc-heap" "ghc-internal" "ghc-platform" "ghc-prim" "ghci" "haskeline" "hpc" "integer-gmp" "mtl" "os-string" "parsec" "pretty" "process" "semaphore-compat" "stm" "template-haskell" "terminfo" "text" "time" "transformers" "unix" "xhtml" "haddock-api" "haddock-library"
                  ];

                  packages.directory.components.library.configureFlags = [''-f os-string''];
                  packages.file-io.components.library.configureFlags = [''-f os-string''];
                  packages.unix.components.library.configureFlags = [''-f os-string''];

                  # The below two patches are trying to fix errors due to seeming Cabal 3.14 incompatibilities

                  # packages.ghc-boot.prePatch = ''
                  #   mv Setup.hs old.hs
                  #   cp -L old.hs Setup.hs
                  # '';
                  # packages.ghc-boot.patches = [ ./nix/ghc-boot-setup-fix.patch ];

                  # packages.ghc.prePatch = ''
                  #   mv Setup.hs old.hs
                  #   cp -L old.hs Setup.hs
                  # '';
                  # packages.ghc.patches = [ ./nix/ghc-setup-fix.patch ];
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

            hackage = (pkgs.pkgsCross.aarch64-multiplatform-musl.haskell-nix.hackage-package { compiler-nix-name = "ghc9122"; name = "ihaskell"; }).components.library;
          });
        }
    );

  nixConfig = {
    # This sets the flake to use the IOG nix cache.
    # Nix should ask for permission before using it,
    # but remove it here if you do not want it to.
    extra-substituters = ["https://cache.iog.io"];
    extra-trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    allow-import-from-derivation = "true";
  };
}
