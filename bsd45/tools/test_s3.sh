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

LABEL="S3"
echo "S3 acceptance: /bin/sh -c 'echo hello; exit 3'"
log1="$("$ws/tools/run_qemu_test.sh" -Iso "$iso" -Keys "usermode" -WaitFor "user exit" -TimeoutSec 25)"
check "sh -c" "$log1" "execve /bin/sh" "hello" "[user exit 3]"
printf '%s' "$log1" | grep -q 'TRAP' && { echo "  FAIL sh -c: kernel trap" >&2; fails=$((fails+1)); }

echo "S3 acceptance: interactive /bin/sh"
log2="$("$ws/tools/run_qemu_test.sh" -Iso "$iso" -Keys "shell|echo hi there|exit 7" -WaitFor "user exit" -TimeoutSec 25)"
check "interactive" "$log2" "hi there" "[user exit 7]"
printf '%s' "$log2" | grep -q 'TRAP' && { echo "  FAIL interactive: kernel trap" >&2; fails=$((fails+1)); }

if [ "$fails" -ne 0 ]; then echo "$LABEL: FAILED ($fails check(s))" >&2; exit 1; fi
echo "$LABEL: PASSED"
exit 0
