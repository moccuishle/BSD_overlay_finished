#!/usr/bin/env bash
# reorganize.sh - one-time migration: merge the extracted 4.4BSD sys tree and
# userland into the Linux-like kernel/ and libc/ trees.  Idempotent: missing
# sources are skipped, so ensure-src.sh can call it after a fresh extraction.
set -uo pipefail
ws="$(cd "$(dirname "$0")/.." && pwd)"
sys="$ws/src/BSD45/usr/src/sys"
k="$ws/kernel"
lc="$ws/libc"

md() {   # md <src> <dst>
    [ -e "$1" ] || { echo "  skip (missing): $1"; return; }
    mkdir -p "$(dirname "$2")"
    if [ -e "$2" ]; then
        mv "$1"/* "$2"/ 2>/dev/null
        rmdir "$1" 2>/dev/null
    else
        mv "$1" "$2"
    fi
    echo "  $(basename "$1") -> ${2#$ws/}"
}

mkdir -p "$k"/{include/sys,include/machine,include/libkern,arch,fs,vm,driver,net,other}
mkdir -p "$lc"/{include,src}

md "$sys/sys"          "$k/include/sys"
md "$sys/i386/include" "$k/include/machine"
md "$sys/i386/i386"    "$k/arch/i386"
for a in hp hp300 luna68k news3400 pmax sparc tahoe vax; do md "$sys/$a" "$k/arch/$a"; done
md "$sys/i386/conf"    "$k/arch/i386/conf"
for d in "$sys"/i386/*/; do
    n="$(basename "$d")"
    case "$n" in include|i386|conf|isa|pci) continue ;; esac
    md "$d" "$k/arch/i386/$n"
done
for d in ufs miscfs isofs msdosfs nfs; do md "$sys/$d" "$k/fs/$d"; done
md "$sys/vm"           "$k/vm"
md "$sys/dev"          "$k/driver/dev"
md "$sys/i386/isa"     "$k/driver/isa"
md "$sys/i386/pci"     "$k/driver/pci_i386"
for d in net netccitt netinet netiso netns; do md "$sys/$d" "$k/net/$d"; done
md "$sys/libkern"      "$k/libkern"
for d in kern conf compile scripts stand stand.att tests; do md "$sys/$d" "$k/other/$d"; done
find "$sys" -maxdepth 1 -type f -exec mv {} "$k/other/" \; 2>/dev/null

[ -d "$k/arch/hp300/include" ] && cp -f "$k/arch/hp300/include/ansi.h" "$k/include/machine/ansi.h" 2>/dev/null
[ -d "$k/arch/hp300/include" ] && cp -f "$k/arch/hp300/include/limits.h" "$k/include/machine/limits.h" 2>/dev/null
[ -d "$k/arch/hp300/include" ] && cp -f "$k/arch/hp300/include/float.h" "$k/include/machine/float.h" 2>/dev/null
[ -f "$k/libkern/libkern.h" ] && cp -f "$k/libkern/libkern.h" "$k/include/libkern/libkern.h" 2>/dev/null

# project sources that used to sit flat in kernel/
for f in usermode.c usermode_asm.s glue.c mon.c stubs.c strings.c; do
    [ -f "$k/$f" ] && md "$k/$f" "$k/other/$f"
done
for f in vfs.c vfs.h isofs.c isofs.h; do [ -f "$k/$f" ] && md "$k/$f" "$k/fs/$f"; done
for f in atapi.c atapi.h pccon.c; do [ -f "$k/$f" ] && md "$k/$f" "$k/driver/$f"; done

# userland -> libc
ul="$ws/userland"
if [ -d "$ul" ]; then
    [ -f "$ul/include/stdarg.h" ] && md "$ul/include/stdarg.h" "$lc/include/stdarg.h"
    for f in ctype.h histedit.h; do [ -f "$ul/libc/$f" ] && md "$ul/libc/$f" "$lc/include/$f"; done
    for f in "$ul"/libc/*; do [ -e "$f" ] && md "$f" "$lc/src/$(basename "$f")"; done
    for f in "$ul"/*.c; do [ -e "$f" ] && md "$f" "$lc/src/$(basename "$f")"; done
    [ -d "$ul/hostgen" ] && md "$ul/hostgen" "$lc/src/hostgen"
    rm -rf "$ul"
fi

bash "$ws/tools/gen-config-mk.sh" "$k" || true
echo "layout done"
