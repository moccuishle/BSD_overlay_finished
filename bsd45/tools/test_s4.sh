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

LABEL="S4"
echo "S4 acceptance: ISO9660 root + sh from the CD"
log="$("$ws/tools/run_qemu_test.sh" -Iso "$iso" -Keys "cd|usermode" -WaitFor "user exit" -TimeoutSec 30)"
check "mount" "$log" "ISO9660 on ATAPI CD" "ISO9660 root: lba"
check "exec from CD" "$log" "via vnode" "hello" "[user exit 3]"
check "no fallback" "$log" "execve /bin/sh: via vnode"
printf '%s' "$log" | grep -q 'from ramfs' && { echo "  FAIL the shell came from the embedded ramfs, not the CD" >&2; fails=$((fails+1)); }
printf '%s' "$log" | grep -q 'TRAP' && { echo "  FAIL kernel trap" >&2; fails=$((fails+1)); }

if [ "$fails" -ne 0 ]; then echo "$LABEL: FAILED ($fails check(s))" >&2; exit 1; fi
echo "$LABEL: PASSED"
exit 0
