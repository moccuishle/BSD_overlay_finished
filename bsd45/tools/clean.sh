#!/usr/bin/env bash
# clean.sh - remove generated directories without touching the sources.
#   clean.sh          -> build/
#   clean.sh -a       -> build/ and out/
# src/ (the extracted 4.4BSD tree) is never removed.
set -uo pipefail
ws="$(cd "$(dirname "$0")/.." && pwd)"
all=0
[ "${1:-}" = "-a" ] || [ "${1:-}" = "--all" ] && all=1

rm -rf "$ws/build"
[ "$all" -eq 1 ] && rm -rf "$ws/out"
echo "kept: src (never removed)"
echo "build: $([ -d "$ws/build" ] && echo present || echo removed)   out: $([ -d "$ws/out" ] && echo present || echo removed)"
