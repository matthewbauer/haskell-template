#!/usr/bin/env bash

set -e

cabal clean
cabal build example \
  --ghc-options=-ddump-simpl \
  --ghc-options=-ddump-to-file \
  --ghc-options=-dsuppress-coercions \
  --ghc-options=-dsuppress-uniques
