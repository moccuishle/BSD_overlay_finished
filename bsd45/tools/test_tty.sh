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

LABEL="S6"
echo "S6 acceptance: console tty"
log1="$("$ws/tools/run_qemu_test.sh" -Iso "$iso" -Keys "test" -WaitFor "user exit" -TimeoutSec 30)"
check "tty" "$log1" "tty: isatty=1/1/1 tcgetattr=0" "tty: iflag=" "lflag="
printf '%s' "$log1" | grep -q 'TRAP' && { echo "  FAIL tty: kernel trap" >&2; fails=$((fails+1)); }

echo "S6 acceptance: interactive sh prompt"
log2="$("$ws/tools/run_qemu_test.sh" -Iso "$iso" -Keys "shell|echo hi-tty|exit 0" -WaitFor "user exit" -TimeoutSec 30)"
check "sh" "$log2" "# echo hi-tty" "hi-tty" "[user exit 0]"
printf '%s' "$log2" | grep -q 'TRAP' && { echo "  FAIL sh: kernel trap" >&2; fails=$((fails+1)); }

if [ "$fails" -ne 0 ]; then echo "$LABEL: FAILED ($fails check(s))" >&2; exit 1; fi
echo "$LABEL: PASSED"
exit 0
