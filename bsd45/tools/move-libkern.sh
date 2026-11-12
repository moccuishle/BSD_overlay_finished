#!/usr/bin/env bash
# move-libkern.sh - one-time helper: rename kernel/lib to kernel/libkern and
# merge other/libkern into it.
set -uo pipefail
ws="$(cd "$(dirname "$0")/.." && pwd)"
k="$ws/kernel"
lib="$k/lib"; lk="$k/libkern"; src="$k/other/libkern"

if [ -d "$lib" ]; then
    if [ -d "$lk" ]; then rm -rf "$lib"; else mv "$lib" "$lk"; fi
fi
mkdir -p "$lk"
if [ -d "$src" ]; then
    find "$src" -maxdepth 1 -mindepth 1 -exec mv {} "$lk/" \; 2>/dev/null
    rmdir "$src" 2>/dev/null || true
fi
rm -f "$lk/.keep"

# build_kernel.sh: libkern now lives in kernel/libkern
sed -i -e 's|\$src/other/libkern/|\$src/libkern/|g' "$ws/build_kernel.sh" 2>/dev/null || true
# reorganize.sh: fresh clones put sys/libkern into kernel/libkern
sed -i -e 's|"$k/other/libkern"|"$k/libkern"|g' "$ws/tools/reorganize.sh" 2>/dev/null || true

echo "kernel/libkern files: $(find "$lk" -maxdepth 1 -type f | wc -l)"
