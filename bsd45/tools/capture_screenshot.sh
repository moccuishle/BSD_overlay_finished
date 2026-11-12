#!/usr/bin/env bash
# capture_screenshot.sh - boot the ISO, type a few commands and save the
# VGA screen as PNG (needs python3 + Pillow, or ImageMagick's convert).
#
#   capture_screenshot.sh [-Keys "shell|ls /|exit 0"] [-Out shot.png]
set -uo pipefail
ws="$(cd "$(dirname "$0")/.." && pwd)"
. "$ws/tools-find.sh"

iso="$ws/out/BSD45-ELF-x86.iso"
out="$ws/build/screenshot.png"
keys="shell|/bin/echo hello-external|exit 0"
ser=$((5800 + RANDOM % 100)); mon=$((4600 + RANDOM % 100))

while [ $# -gt 0 ]; do
    case "$1" in
        -Keys) keys="$2"; shift 2 ;;
        -Out)  out="$2"; shift 2 ;;
        -Iso)  iso="$2"; shift 2 ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done

qemu="$(find_qemu)" || { echo "qemu-system-i386 not found" >&2; exit 1; }
mkdir -p "$(dirname "$out")"
ppm="${out%.png}.ppm"
rm -f "$ppm"

"$qemu" -cdrom "$iso" -boot d -m 64 -display none -no-reboot \
    -serial "tcp:127.0.0.1:$ser,server=on,wait=on" \
    -monitor "tcp:127.0.0.1:$mon,server=on,nowait" &
qpid=$!
trap 'kill "$qpid" 2>/dev/null' EXIT

ok=0
for _ in $(seq 1 100); do
    if (exec 3<>"/dev/tcp/127.0.0.1/$ser") 2>/dev/null; then ok=1; break; fi
    sleep 0.1
done
[ "$ok" -eq 1 ] || { echo "cannot connect to serial" >&2; exit 1; }
exec 3<>"/dev/tcp/127.0.0.1/$ser"

pump() {
    local end=$(( $(date +%s%N) / 1000000 + $1 )) data
    while [ $(( $(date +%s%N) / 1000000 )) -lt "$end" ]; do
        if IFS= read -r -t 0.05 -u 3 -n 4096 data 2>/dev/null; then :; fi
    done
}
wait_text() {
    local end=$(( $(date +%s) + $2 ))
    while [ "$(date +%s)" -lt "$end" ]; do
        pump 150
        (exec 4<>"/dev/tcp/127.0.0.1/$mon") 2>/dev/null && exec 4<&- || true
        # cannot peek the serial log; rely on a fixed settle time
        return 0
    done
}
sleep 6
IFS='|' read -r -a cmdlist <<< "$keys"
for k in "${cmdlist[@]}"; do
    [ -n "$k" ] || continue
    printf '%s\r' "$k" >&3
    pump 1200
done
pump 1200

exec 4<>"/dev/tcp/127.0.0.1/$mon"
printf 'screendump %s\n' "$ppm" >&4
sleep 1
exec 4<&-

if [ -f "$ppm" ]; then
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$ppm" "$out" <<'PY'
import sys
from PIL import Image
Image.open(sys.argv[1]).save(sys.argv[2])
PY
    elif command -v convert >/dev/null 2>&1; then
        convert "$ppm" "$out"
    fi
fi
echo "screenshot: $out"
