#!/usr/bin/env bash
# fix-arch.sh - one-time helper: 4.5BSD sources include each other as
# "i386/i386/..." and "i386/isa/...", so keep that nesting under arch/i386.
set -uo pipefail
ws="$(cd "$(dirname "$0")/.." && pwd)"
k="$ws/kernel"
arch="$k/arch/i386"
inner="$arch/i386"
mkdir -p "$inner"
# flat files back into arch/i386/i386
find "$arch" -maxdepth 1 -type f -exec mv {} "$inner/" \; 2>/dev/null
[ -d "$k/driver/isa" ] && { rm -rf "$arch/isa"; mv "$k/driver/isa" "$arch/isa"; }
[ -d "$k/driver/pci_i386" ] && { rm -rf "$arch/pci"; mv "$k/driver/pci_i386" "$arch/pci"; }
echo "arch/i386:"
find "$arch" -maxdepth 1 -mindepth 1 -type d -printf '  %f/\n' | sort
echo "arch/i386/i386 files: $(find "$inner" -maxdepth 1 -type f | wc -l)"
