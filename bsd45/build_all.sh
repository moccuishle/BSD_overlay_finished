#!/usr/bin/env bash
# build_all.sh - userland -> /bin/sh -> /test -> kernel -> ISO.
set -euo pipefail
ws="$(cd "$(dirname "$0")" && pwd)"

bash "$ws/build_userland.sh"
bash "$ws/build_sh.sh"
bash "$ws/build_sh.sh" -t test
bash "$ws/build_kernel.sh"
bash "$ws/build_iso.sh"
echo "all done"
