import io

W = r"C:\Users\Administrator\Desktop\work\bsd45"

def patch(path, pairs):
    t = io.open(path, encoding="utf-8", newline="").read().replace("\r\n", "\n")
    for a, b in pairs:
        assert a in t, (path, a)
        t = t.replace(a, b, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(t)
    print("patched", path.rsplit("\\", 1)[-1])

# kernel: C compiles must use the a.out-style leading underscore that the
# 4.4BSD assembly (locore.s, icu.s) and our usermode_asm.s expect.
patch(W + r"\build_kernel.sh", [
    ('cflags=(-m32 -std=gnu89 -O2 -ffreestanding',
     'cflags=(-m32 -std=gnu89 -O2 -ffreestanding -fleading-underscore'),
])

# userland: crt0.s calls _main/_exit, init.c/sh.c asm calls _start_c
patch(W + r"\build_userland.sh", [
    ('CFLAGS=(-m32 -O2 -ffreestanding -fno-pie -fno-pic',
     'CFLAGS=(-m32 -O2 -ffreestanding -fleading-underscore -fno-pie -fno-pic'),
])

patch(W + r"\build_sh.sh", [
    ('common=(-m32 -std=gnu89 -O2 -ffreestanding -fno-builtin',
     'common=(-m32 -std=gnu89 -O2 -ffreestanding -fno-builtin -fleading-underscore'),
])
