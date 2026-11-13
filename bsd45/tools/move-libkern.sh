#!/usr/bin/env bash
# move-libkern.sh - one-time helper: kernel/libkern was renamed to kernel/lib.
# Idempotent: renames the directory and the header dir, rewrites references.
set -uo pipefail
ws="$(cd "$(dirname "$0")/.." && pwd)"
k="$ws/kernel"

if [ -d "$k/libkern" ] && [ ! -d "$k/lib" ]; then
    mv "$k/libkern" "$k/lib"
    echo "kernel/libkern -> kernel/lib"
fi
if [ -d "$k/include/libkern" ] && [ ! -d "$k/include/lib" ]; then
    mv "$k/include/libkern" "$k/include/lib"
    echo "kernel/include/libkern -> kernel/include/lib"
fi

grep -rl '#include <libkern/' "$k" 2>/dev/null | while read -r f; do
    sed -i 's|#include <libkern/|#include <lib/|g' "$f"
done
echo "kernel/lib files: $(find "$k/lib" -maxdepth 1 -type f 2>/dev/null | wc -l)"
