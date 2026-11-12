#!/usr/bin/env bash
# test_kbd.sh - check that PS/2 keyboard input reaches the console.
# Boots twice (with and without keystrokes) and compares the screen dumps.
set -uo pipefail
ws="$(cd "$(dirname "$0")/.." && pwd)"
. "$ws/tools-find.sh"
iso="${1:-$ws/out/BSD45-ELF-x86.iso}"
qemu="$(find_qemu)" || { echo "qemu-system-i386 not found" >&2; exit 1; }

shot() {   # shot <out.ppm> [type-text]
    local out="$1" text="${2:-}" mon=$((4700 + RANDOM % 100))
    "$qemu" -cdrom "$iso" -boot d -m 64 -display none -no-reboot \
        -serial none -monitor "tcp:127.0.0.1:$mon,server=on,nowait" &
    local pid=$!
    sleep 7
    if [ -n "$text" ]; then
        exec 4<>"/dev/tcp/127.0.0.1/$mon"
        printf 'sendkey %s\n' "$text" >&4
        sleep 1
        exec 4<&-
    fi
    exec 4<>"/dev/tcp/127.0.0.1/$mon"
    printf 'screendump %s\n' "$out" >&4
    sleep 1
    exec 4<&-
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
}

a="$(mktemp -u).ppm"; b="$(mktemp -u).ppm"
shot "$a"
shot "$b" "h"
if cmp -s "$a" "$b"; then
    echo "test_kbd: FAILED (screen unchanged after sendkey)" >&2; exit 1
fi
echo "test_kbd: PASSED"
rm -f "$a" "$b"
