{
  description = "example";

  inputs.nixpkgs = {};

  # custom http2 version
  inputs.http2 = {
    url = "github:kazu-yamamoto/http2";
    flake = false;
  };

  outputs = { self, nixpkgs, http2 }: let
    # Configure these values as needed.
    systems = ["x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    compiler = "ghc9103";
    localHaskellPackages = {
      example = self;

      # Add any dependencies here
      inherit http2;
    };

    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlays.localHaskellPackagesOverlay self.overlays.default ]; });
    nixpkgsForNoOverlay = forAllSystems (system: import nixpkgs { inherit system; });
  in {
    packages = forAllSystems (system: {
      default = self.packages.${system}.example;
      example = nixpkgsFor.${system}.haskell.packages.${compiler}.example;

      # Add more packages as needed
    });

    devShells = forAllSystems (system: {
      default = self.devShells.${system}.example;

      example = (self.packages.${system}.example.envFunc { }).overrideAttrs (drv: {
        nativeBuildInputs = (drv.nativeBuildInputs or [ ]) ++ (with nixpkgsFor.${system}.haskell.packages.${compiler}; [
          hlint
          cabal-install
          haskell-language-server
          ormolu
          hp2pretty
          eventlog2html
        ]);
        shellHook = self.devShells.${system}.generate-nix.shellHook;
      });

      # Add more shells as needed

      generate-nix = nixpkgsForNoOverlay.${system}.mkShell {
        shellHook = let
          deps = with nixpkgsForNoOverlay.${system}; [
            haskell.packages.${compiler}.cabal2nix
            nix
            nix-prefetch-scripts
            git
            coreutils
            gnused
          ];
        in ''
          set -e
          set -o pipefail

          PATH="$PATH''${PATH:+:}${nixpkgsForNoOverlay.${system}.lib.makeBinPath deps}"

          changed=0

          generated_nix_dir="$(git rev-parse --show-toplevel)/generated-nix"

          while read -r name && read -r src; do
            mkdir -p "$generated_nix_dir"
            file="$generated_nix_dir/$name.nix"
            old_hash=
            if [ -f "$file" ]; then
                old_hash="$(nix hash file "$file")"
            fi
            tmpfile="$(mktemp)"
            if cabal2nix "$src" >| "$tmpfile"; then
                command cp -f "$tmpfile" "$file"
            fi
            command rm -f "$tmpfile"
            sed -i 's,^ *src = [^;]*;$,  src = throw "missing src definition";,' "$file"
            if [ "$old_hash" != "$(nix hash file "$file")" ]; then
                git add "$file"
                changed=1
            fi
          done < <(jq -r "to_entries[] | .key, .value" <<<'${builtins.toJSON localHaskellPackages}')

          if [ "$changed" -ne 0 ]; then
            echo "Generated Nix scripts updated. Exiting."
            echo "Rerun last command to continue."
            exit "$changed"
          fi
        '';
      };
    });

    checks = forAllSystems (system: {
      inherit (self.packages.${system}) example;

      # Add more checks as needed
    });

    overlays.localHaskellPackagesOverlay = final: prev: {
      haskell = prev.haskell // {
        packages = prev.haskell.packages // {
          ${compiler} = prev.haskell.packages.${compiler}.extend (hfinal: hprev:
            builtins.mapAttrs (name: value: let
              file = if builtins.pathExists ./generated-nix/${name}.nix
                     then ./generated-nix/${name}.nix
                     else throw "Missing generated Nix file for ${name}. Rerun 'nix develop .#generate-nix'.";
            in final.haskell.lib.overrideCabal (hfinal.callPackage file { }) (drv: { src = value; })) localHaskellPackages);
        };
      };
    };

    overlays.default = final: prev: {
      haskell = prev.haskell // {
        packages = prev.haskell.packages // {
          ${compiler} = prev.haskell.packages.${compiler}.extend (hfinal: hprev: {
            # my overlay here
          });
        };
      };
    };

  };

  nixConfig.bash-prompt = "\\n\\[\\e[1;32m\\][example:\\w]\\$\\[\\e[0m\\] ";
}
