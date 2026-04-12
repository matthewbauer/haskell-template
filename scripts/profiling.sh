#!/usr/bin/env sh

# Run profiling for binary.
# website to view .prof & .eventlog files: https://www.speedscope.app

cabal run --enable-profiling --profiling-detail=late-toplevel example -- +RTS -hc -l -pj -RTS "$@"
