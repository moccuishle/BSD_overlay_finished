#!/usr/bin/env bash
# tools-find.sh - locate the Linux toolchain pieces used by the build.
# Usage:  . "$ws/tools-find.sh"
set -u

find_gcc()  { command -v gcc 2>/dev/null || command -v cc 2>/dev/null; }
find_ld()   { command -v ld 2>/dev/null; }
find_objcopy() { command -v objcopy 2>/dev/null; }
find_objdump() { command -v objdump 2>/dev/null; }
find_gcc_include() { gcc -print-file-name=include 2>/dev/null; }

find_mkisofs() {
    local c
    if [ -n "${MKISOFS:-}" ] && [ -x "${MKISOFS}" ]; then echo "$MKISOFS"; return 0; fi
    for c in genisoimage mkisofs xorriso; do
        if command -v "$c" >/dev/null 2>&1; then command -v "$c"; return 0; fi
    done
    echo "mkisofs/genisoimage/xorriso not found; install genisoimage or xorriso" >&2
    return 1
}

find_qemu() {
    local c
    if [ -n "${QEMU:-}" ] && [ -x "${QEMU}" ]; then echo "$QEMU"; return 0; fi
    for c in qemu-system-i386 qemu-system-i386.exe; do
        if command -v "$c" >/dev/null 2>&1; then command -v "$c"; return 0; fi
    done
    return 1
}

require_tools() {
    local t
    for t in "$@"; do
        command -v "$t" >/dev/null 2>&1 || { echo "missing tool: $t" >&2; exit 1; }
    done
}
