#!/usr/bin/env bash
# build_iso.sh - build the El Torito boot image and the BSD45-ELF-x86 ISO.
set -uo pipefail
ws="$(cd "$(dirname "$0")" && pwd)"
. "$ws/tools-find.sh"

kernel="${1:-$ws/build/bsd45.elf}"
out_iso="${2:-$ws/out/BSD45-ELF-x86.iso}"
kernel_lba="${3:-2048}"
bld="$ws/build"
boot="$ws/boot"
out="$ws/out"
isodir="$bld/isodir"

require_tools gcc ld objcopy
mkiso="$(find_mkisofs)"
mkdir -p "$out"
rm -rf "$isodir"; mkdir -p "$isodir"

build_stage() {   # build_stage <src> <text> <name> <entry>
    local src="$1" text="$2" name="$3" entry="$4"
    gcc -m32 -c -x assembler-with-cpp -o "$bld/$name.o" "$src" || exit 1
    ld -m elf_i386 -Ttext "$text" -e "$entry" -o "$bld/$name.elf" "$bld/$name.o" || exit 1
    objcopy -O binary --only-section=.text "$bld/$name.elf" "$bld/$name.bin" || exit 1
    echo "$bld/$name.bin"
}

s1="$(build_stage "$boot/stage1.s" 0x7C00  stage1 _start)"
s2="$(build_stage "$boot/stage2.s" 0x90000 stage2 _start32)"
n1=$(stat -c%s "$s1" 2>/dev/null || wc -c < "$s1")
n2=$(stat -c%s "$s2" 2>/dev/null || wc -c < "$s2")
[ "$n1" -eq 512 ] || { echo "stage1 must be 512 bytes, got $n1" >&2; exit 1; }
echo "stage1 $n1 bytes, stage2 $n2 bytes"

# boot image = stage1 || stage2, padded to 4 KiB
img="$bld/boot.img"
dd if=/dev/zero of="$img" bs=4096 count=1 status=none
dd if="$s1" of="$img" bs=1 seek=0 conv=notrunc status=none
dd if="$s2" of="$img" bs=1 seek=512 conv=notrunc status=none

# patch the manifest: "BDMF" lba bytes stage2size
off=$(LC_ALL=C grep -abo -m1 'BDMF' "$img" 2>/dev/null | cut -d: -f1 || true)
[ -n "$off" ] || { echo "manifest magic not found" >&2; exit 1; }
put32() {  # put32 <value> <offset>
    python3 - "$1" "$2" "$img" <<'PY'
import struct, sys
val, off, path = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
with open(path, "r+b") as f:
    f.seek(off); f.write(struct.pack("<I", val & 0xffffffff))
PY
}
put32 "$kernel_lba" $((off + 4))
put32 "$(stat -c%s "$kernel" 2>/dev/null || wc -c < "$kernel")" $((off + 8))
put32 "$n2" $((off + 12))

cp -f "$kernel" "$isodir/BSD45.ELF"
mkdir -p "$isodir/bin" "$isodir/sbin"
for pair in "sh:bin/SH.ELF" "init:sbin/INIT.ELF" "hello:HELLO.ELF" "test:TEST.ELF" \
            "ls:bin/LS.ELF" "mkdir:bin/MKDIR.ELF" "cat:bin/CAT.ELF" "echo:bin/ECHO.ELF"; do
    name="${pair%%:*}"; dst="${pair#*:}"
    [ -f "$ws/out/userland/$name.elf" ] && cp -f "$ws/out/userland/$name.elf" "$isodir/$dst"
done
cp -f "$img" "$isodir/boot.img"

# rootfs_overlay/ is copied on top of the ISO root
if [ -d "$ws/rootfs_overlay" ]; then
    cp -a "$ws/rootfs_overlay/." "$isodir/"
fi
find "$isodir" -name .keep -delete 2>/dev/null

rm -f "$out_iso"
case "$(basename "$mkiso")" in
    xorriso) "$mkiso" -as mkisofs -quiet -iso-level 1 -V BSD45_ELF_X86 \
                 -b boot.img -c boot.cat -no-emul-boot -boot-load-size 8 \
                 -o "$out_iso" "$isodir" ;;
    *)       "$mkiso" -quiet -iso-level 1 -V BSD45_ELF_X86 \
                 -b boot.img -c boot.cat -no-emul-boot -boot-load-size 8 \
                 -o "$out_iso" "$isodir" ;;
esac || { echo "mkisofs failed" >&2; exit 1; }

# pad to the kernel LBA, append the ELF kernel, pad to a CD sector
iso_size=$(stat -c%s "$out_iso" 2>/dev/null || wc -c < "$out_iso")
target=$((kernel_lba * 2048))
[ "$iso_size" -le "$target" ] || { echo "ISO already larger than kernel LBA" >&2; exit 1; }
dd if=/dev/zero bs=1 count=$((target - iso_size)) status=none >> "$out_iso"
cat "$kernel" >> "$out_iso"
kbytes=$(stat -c%s "$kernel" 2>/dev/null || wc -c < "$kernel")
pad2=$(( (2048 - (kbytes % 2048)) % 2048 ))
[ "$pad2" -gt 0 ] && dd if=/dev/zero bs=1 count="$pad2" status=none >> "$out_iso"

echo "ISO: $out_iso ($(stat -c%s "$out_iso" 2>/dev/null || wc -c < "$out_iso") bytes), kernel at LBA $kernel_lba"
