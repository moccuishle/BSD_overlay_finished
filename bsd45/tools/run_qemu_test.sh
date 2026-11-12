#!/usr/bin/env bash
# run_qemu_test.sh - boot the BSD45 ISO in QEMU and drive the serial console.
#
#   run_qemu_test.sh -Keys "shell|ls /|exit 0" -WaitFor "user exit"
#
# The serial port is a TCP server; bash's /dev/tcp is used as the client, so
# no extra tooling is needed.
set -uo pipefail
ws="$(cd "$(dirname "$0")/.." && pwd)"
. "$ws/tools-find.sh"

iso="$ws/out/BSD45-ELF-x86.iso"
keys=""
waitfor="user exit"
timeout=30
log_out=""
port="${SERIAL_PORT:-$((5700 + RANDOM % 200))}"

while [ $# -gt 0 ]; do
    case "$1" in
        -Iso)        iso="$2"; shift 2 ;;
        -Keys)       keys="$2"; shift 2 ;;
        -WaitFor)    waitfor="$2"; shift 2 ;;
        -TimeoutSec) timeout="$2"; shift 2 ;;
        -Log)        log_out="$2"; shift 2 ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done

qemu="$(find_qemu)" || { echo "qemu-system-i386 not found" >&2; exit 1; }
[ -f "$iso" ] || { echo "no ISO at $iso" >&2; exit 1; }

log="$(mktemp)"
trap 'rm -f "$log"; [ -n "${qpid:-}" ] && kill "$qpid" 2>/dev/null' EXIT

"$qemu" -cdrom "$iso" -boot d -m 64 -display none -no-reboot \
    -serial "tcp:127.0.0.1:$port,server=on,wait=on" -monitor none &
qpid=$!

# wait for the serial server
ok=0
for _ in $(seq 1 100); do
    if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then ok=1; break; fi
    sleep 0.1
done
[ "$ok" -eq 1 ] || { echo "cannot connect to serial port $port" >&2; exit 1; }
exec 3<>"/dev/tcp/127.0.0.1/$port"

# a background reader keeps the socket drained; the console prompt has no
# trailing newline, so line-based read would lose it
( cat <&3 >> "$log" ) &
catpid=$!

wait_text() {   # wait_text <pattern> <seconds>
    local end=$(( $(date +%s) + $2 ))
    while [ "$(date +%s)" -lt "$end" ]; do
        grep -q "$1" "$log" 2>/dev/null && return 0
        sleep 0.15
    done
    return 1
}

if ! wait_text "bsd45>" "$timeout"; then
    echo "boot timeout: no monitor prompt" >&2
    cat "$log" >&2
    exit 1
fi

IFS='|' read -r -a cmdlist <<< "$keys"
for k in "${cmdlist[@]}"; do
    [ -n "$k" ] || continue
    printf '%s\r' "$k" >&3
    sleep 1.2
done
if [ -n "$waitfor" ]; then wait_text "$waitfor" 15 || true; fi
sleep 0.5
kill "$catpid" 2>/dev/null || true
exec 3<&-
cat "$log"
if [ -n "$log_out" ]; then cp -f "$log" "$log_out"; fi
grep -q "$waitfor" "$log" || exit 1
exit 0
