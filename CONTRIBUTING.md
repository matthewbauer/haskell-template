Making changes to this codebase

# Dependencies

This project requires Nix to work. If you don’t have Nix, you can
install it at https://nixos.org/download/.

All of the following instructions will assume you have Nix and be
prefixed with `nix develop -c`. You may omit `nix develop -c` if you
are already in a Nix environment.

If any `nix develop -c` command fails with "Generated Nix scripts
updated. Exiting.", then you should rerun the command again.

## Adding a Haskell dependency already in Nixpkgs

Haskell dependencies are provided by Nix, but the Cabal configuration
is a little different than what’s normally seen.

To add a new Haskell dependency, simply add the package to the
`build-depends` field in `trading.cabal`. Then, exit the Nix
environment using `exit`, and run `nix develop`. This will exit with
`Generated Nix scripts updated. Exiting.`; this is normal. Run `nix
develop` once more to get a Nix environment with the new dependencies.

## Adding a Haskell dependency not in Nixpkgs

You can also add a dependency that is not already in Nixpkgs. This
requires adding a new flake input. See "http2" for a provided example.

## Updating the compiler

You can change compiler by setting the "compiler" field in flake.nix.

# Scripts

Some other scripts are available in the ./scripts/ directory. Here is
a list of useful ones:

- ./scripts/ci.sh - Run CI
- ./scripts/profiling.sh - Run binary with profiling enabled.

# Testing changes

To test that a change works, you need to use `cabal`:

```
nix develop -c cabal repl
```

Before finishing a change, make sure it passes continuous integration with:

```
nix develop -c ./scripts/ci.sh
```
