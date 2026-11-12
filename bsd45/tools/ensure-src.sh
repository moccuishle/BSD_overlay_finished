#!/usr/bin/env bash
# ensure-src.sh - extract the 4.4BSD-Lite2 tree when src/BSD45 is missing,
# then make sure the kernel/ layout exists.
set -euo pipefail
ws="$(cd "$(dirname "$0")/.." && pwd)"
srcroot="$ws/src/BSD45"
marker="$srcroot/usr/src/lib/libc/gen/opendir.c"
tarball="$ws/../4.4BSD-Lite2.tar.gz"
[ -f "$tarball" ] || tarball="$ws/4.4BSD-Lite2.tar.gz"

if [ -f "$marker" ]; then
    :
elif [ ! -f "$tarball" ]; then
    echo "4.4BSD-Lite2.tar.gz not found next to the project" >&2
    exit 1
else
    echo "extracting $tarball"
    mkdir -p "$ws/src"
    rm -rf "$srcroot"
    tar -xzf "$tarball" -C "$ws/src"
    if [ -d "$ws/src/4.4BSD-Lite2" ] && [ ! -d "$srcroot" ]; then
        mv "$ws/src/4.4BSD-Lite2" "$srcroot"
    fi
    chmod -R u+w "$srcroot" 2>/dev/null || true
    [ -f "$marker" ] || { echo "extraction failed: $marker missing" >&2; exit 1; }
fi

if [ ! -f "$ws/kernel/arch/i386/i386/locore.s" ] && [ -d "$ws/src/BSD45/usr/src/sys" ]; then
    bash "$ws/tools/reorganize.sh"
fi
