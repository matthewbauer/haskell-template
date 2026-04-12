#!/usr/bin/env bash

# Run everything necessary to verify new changes work.

set -e

find . -name '*.hs' | xargs -- fourmolu -i
hlint src/
cabal build
