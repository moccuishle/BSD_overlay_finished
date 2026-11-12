#!/usr/bin/env bash
# gen-config-mk.sh - put a config.mk in every directory of the kernel tree.
set -euo pipefail
ws="$(cd "$(dirname "$0")/.." && pwd)"
root="${1:-$ws/kernel}"
[ -d "$root" ] || { echo "no kernel tree at $root" >&2; exit 1; }

count=0
while IFS= read -r -d '' dir; do
    rel="${dir#$root/}"
    out="$dir/config.mk"
    {
        echo "# config.mk - kernel/$rel"
        echo "#"
        echo "# Per-directory build configuration for the BSD45 kernel."
        echo "# build_kernel.sh is the current driver; a kbuild-style build can"
        echo "# pick up obj-y/obj-m/dir-y from here."
        echo ""
        echo "# obj-y += "
        echo "# obj-m += "
        echo "# dir-y += "
        srcs=$(find "$dir" -maxdepth 1 -type f \( -name '*.c' -o -name '*.s' -o -name '*.S' \) -printf '%f\n' | sort)
        if [ -n "$srcs" ]; then
            echo ""
            echo "# sources in this directory:"
            echo "$srcs" | sed 's/^/#   /'
        fi
        subs=$(find "$dir" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort)
        if [ -n "$subs" ]; then
            echo ""
            echo "# subdirectories:"
            echo "$subs" | sed 's|^|#   |; s|$|/|'
        fi
    } > "$out"
    count=$((count + 1))
done < <(find "$root" -mindepth 1 -type d -print0 | sort -z)
echo "config.mk written in $count directories under $root"
