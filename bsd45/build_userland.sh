#!/usr/bin/env bash
# build_userland.sh - build the small i386 ELF user programs (hello/init/sh).
set -euo pipefail
ws="$(cd "$(dirname "$0")" && pwd)"
. "$ws/tools-find.sh"
out="${1:-$ws/out/userland}"
mkdir -p "$out"
require_tools gcc ld

CFLAGS=(-m32 -O2 -ffreestanding -fno-pie -fno-pic
    -fno-stack-protector -fno-asynchronous-unwind-tables -fno-unwind-tables
    -nostdlib -nostdinc -march=i386 -mno-sse -mno-sse2 -mno-mmx -mno-avx
    -mpreferred-stack-boundary=2)
LIBGCC="$(gcc -m32 -print-libgcc-file-name)"

build_user_elf() {
    local src="$1" name="$2"
    gcc "${CFLAGS[@]}" -c -o "$out/$name.o" "$src"
    ld -m elf_i386 -Ttext 0x08048000 -e _start -o "$out/$name.elf" \
        "$out/$name.o" "$LIBGCC"
    echo "  $name.elf"
}

echo "building userland ELF32"
build_user_elf "$ws/libc/src/hello.c" hello
build_user_elf "$ws/libc/src/init.c"  init
build_user_elf "$ws/libc/src/sh.c"    sh
echo "done -> $out"
