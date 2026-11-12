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

LABEL="S5"
echo "S5 acceptance: fork / vfork / wait4"
log="$("$ws/tools/run_qemu_test.sh" -Iso "$iso" -Keys "test" -WaitFor "user exit" -TimeoutSec 30)"
check "proc" "$log" "S:fork" "C:fork" "fork waited pid=2 code=5" \
    "S:vfork" "vfork-exec-ok" "vfork waited pid=3 code=0" "done" "[user exit 0]"
printf '%s' "$log" | grep -q 'TRAP' && { echo "  FAIL kernel trap" >&2; fails=$((fails+1)); }

if [ "$fails" -ne 0 ]; then echo "$LABEL: FAILED ($fails check(s))" >&2; exit 1; fi
echo "$LABEL: PASSED"
exit 0
