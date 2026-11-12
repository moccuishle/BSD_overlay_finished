#!/usr/bin/env bash
set -uo pipefail
ws="$(cd "$(dirname "$0")/.." && pwd)"
iso="${1:-$ws/out/BSD45-ELF-x86.iso}"
[ -f "$iso" ] || { echo "ISO not found: $iso" >&2; exit 1; }
fails=0
check() {   # check <name> <log> <needle...>
    local name="$1" log="$2" n
    shift 2
    for n in "$@"; do
        if printf '%s' "$log" | grep -qF -- "$n"; then
            echo "  ok   $name: found $n"
        else
            echo "  FAIL $name: missing $n" >&2
            fails=$((fails + 1))
        fi
    done
}

LABEL="S8"
echo "S8 acceptance: tmpfs + redirection"
log="$("$ws/tools/run_qemu_test.sh" -Iso "$iso" \
    -Keys "shell|echo hello-tmpfs > /tmp/a|cat /tmp/a|echo second >> /tmp/a|cat /tmp/a|mkdir /tmp/d|ls /tmp|exit 0" \
    -WaitFor "user exit" -TimeoutSec 60)"
check "write"  "$log" "hello-tmpfs"
check "append" "$log" "second"
check "mkdir"  "$log" "d"
check "ls"     "$log" "a"
check "exit"   "$log" "[user exit 0]"
printf '%s' "$log" | grep -q 'TRAP' && { echo "  FAIL kernel trap" >&2; fails=$((fails+1)); }
printf '%s' "$log" | grep -q 'No such file' && { echo "  FAIL unexpected ENOENT" >&2; fails=$((fails+1)); }

if [ "$fails" -ne 0 ]; then echo "$LABEL: FAILED ($fails check(s))" >&2; exit 1; fi
echo "$LABEL: PASSED"
exit 0
