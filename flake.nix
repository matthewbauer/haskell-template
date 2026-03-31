{
  description = "example";

  inputs.nixpkgs = {};

  outputs = { self, nixpkgs }: let
    forAllSystems = f: nixpkgs.lib.genAttrs ["x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux"] (system: f system);
    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlays.default ]; });
    compiler = "ghc9122";
  in {
    overlays.default = final: prev: {
      haskell = prev.haskell // {
        packages = prev.haskell.packages // {
          ${compiler} = prev.haskell.packages.${compiler}.extend (hfinal: hprev: let
            inherit (final.haskell.lib) overrideCabal;
          in {
            example = overrideCabal (hfinal.callPackage ./generated-nix/example.nix { }) (drv: { src = self; });
          });
        };
      };
    };
    packages = forAllSystems (system: {
      default = self.packages.${system}.example;
      example = nixpkgsFor.${system}.haskell.packages.${compiler}.example;
    });
    devShells = forAllSystems (system: {
      default = self.devShells.${system}.example;
      generate-nix = nixpkgsFor.${system}.mkShell {
        shellHook = let deps = with nixpkgsFor.${system}; [haskell.packages.${compiler}.cabal2nix nix nix-prefetch-scripts git coreutils gnused];
        in ''
          set -e

          PATH="$PATH''${PATH:+:}${nixpkgsFor.${system}.lib.makeBinPath deps}"

          changed=0

          generated_cabals=( example )

          generated_nix_dir="$(git rev-parse --show-toplevel)/generated-nix"

          for name in "''${generated_cabals[@]}"; do
              src=
              if [ "$name" = example ]; then
                  src=$(nix eval --raw --impure --expr "((builtins.getFlake (builtins.toString ./.)).outPath)")
              else
                  src=$(nix eval --raw --impure --expr "((builtins.getFlake (builtins.toString ./.)).inputs.$name.outPath)")
              fi

              mkdir -p $generated_nix_dir
              file=$generated_nix_dir/$name.nix
              old_hash=
              if [ -f "$file" ]; then
                  old_hash=$(nix hash file "$file")
              fi
              tmpfile=$(mktemp)
              if cabal2nix "$src" >| "$tmpfile"; then
                  command cp -f "$tmpfile" "$file"
              fi
              command rm -f $tmpfile
              sed -i 's,^ *src = [^;]*;$,  src = throw "missing src definition";,' "$file"
              if [ "$old_hash" != "$(nix hash file "$file")" ]; then
                  git add "$file"
                  changed=1
              fi
          done

          if [ "$changed" -ne 0 ]; then
            echo "Generated Nix scripts updated. Exiting."
            exit $changed
          fi
        '';
      };
      example = (self.packages.${system}.example.envFunc { }).overrideAttrs (drv: let
        haskellPackages = nixpkgsFor.${system}.haskell.packages.${compiler};
      in {
        nativeBuildInputs = (drv.nativeBuildInputs or [ ]) ++ [ haskellPackages.hlint haskellPackages.cabal-install haskellPackages.ghcid haskellPackages.haskell-language-server haskellPackages.ormolu haskellPackages.hp2pretty haskellPackages.eventlog2html ];
        shellHook = self.devShells.${system}.generate-nix.shellHook;
      });
    });
    checks = forAllSystems (system: {
      inherit (self.packages.${system}) examples;
    });
  };

  nixConfig.bash-prompt = "\\n\\[\\e[1;32m\\][example:\\w]\\$\\[\\e[0m\\] ";
}
