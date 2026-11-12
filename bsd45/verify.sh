#!/usr/bin/env bash
# verify.sh - boot the ISO in QEMU and check the expected banner/output.
set -euo pipefail
ws="$(cd "$(dirname "$0")" && pwd)"
. "$ws/tools-find.sh"
iso="${1:-$ws/out/BSD45-ELF-x86.iso}"
qemu="$(find_qemu)" || { echo "qemu-system-i386 not found" >&2; exit 1; }
[ -f "$iso" ] || { echo "no ISO at $iso" >&2; exit 1; }

log="$(mktemp)"
trap 'rm -f "$log"' EXIT
"$qemu" -cdrom "$iso" -boot d -m 64 -display none -no-reboot \
    -serial "file:$log" -monitor none &
pid=$!
sleep 8
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true

rc=0
for pat in "4.4BSD-Lite2 (i386) ELF kernel" \
           "root: ISO9660 on ATAPI CD" \
           "BSD/386 monitor"; do
    if grep -q "$pat" "$log"; then
        echo "  ok   $pat"
    else
        echo "  FAIL $pat" >&2
        rc=1
    fi
done
if [ "$rc" -eq 0 ]; then echo "verify: PASSED"; else echo "verify: FAILED" >&2; exit 1; fi
