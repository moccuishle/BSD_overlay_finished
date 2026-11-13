import io, os, shutil, re

W = r"C:\Users\Administrator\Desktop\work\bsd45"
ROOT = r"C:\Users\Administrator\Desktop\work"

def rd(p):
    return io.open(p, encoding="utf-8", errors="surrogateescape", newline="").read().replace("\r\n", "\n")

def wr(p, t):
    io.open(p, "w", encoding="utf-8", errors="surrogateescape", newline="\n").write(t)

# ================================================================ 1. 4.4BSD -> 4.5BSD in scripts
changed = []
for root, dirs, files in os.walk(W):
    if "\\src" in root or "\\build" in root or "\\out" in root:
        continue
    for f in files:
        if not f.endswith((".sh", ".ps1")):
            continue
        p = os.path.join(root, f)
        t = rd(p)
        if "4.4BSD" in t:
            t = t.replace("4.4BSD", "4.5BSD")
            wr(p, t)
            changed.append(os.path.relpath(p, W))
print("scripts updated:", len(changed))
for c in changed:
    print("  ", c)

# ================================================================ 2. kernel banner strings
banners = {
    os.path.join(W, r"kernel\other\glue.c"): [
        ('printf("4.4BSD-Lite2 (i386) ELF kernel\\n");', 'printf("4.5BSD-Lite2 (i386) ELF kernel\\n");'),
    ],
    os.path.join(W, r"kernel\other\mon.c"): [
        ('printf("4.4BSD-Lite2 i386 ELF kernel, KERNBASE %x\\n",', 'printf("4.5BSD-Lite2 i386 ELF kernel, KERNBASE %x\\n",'),
    ],
}
for p, pairs in banners.items():
    t = rd(p)
    for a, b in pairs:
        if a in t:
            t = t.replace(a, b)
    wr(p, t)
    print("banner updated:", os.path.basename(p))

# ================================================================ 3. tarball name
src_tar = os.path.join(ROOT, "4.4BSD-Lite2.tar.gz")
dst_tar = os.path.join(ROOT, "4.5BSD-Lite2.tar.gz")
if os.path.exists(src_tar) and not os.path.exists(dst_tar):
    shutil.move(src_tar, dst_tar)
    print("tarball renamed -> 4.5BSD-Lite2.tar.gz")

# ensure-src: prefer the new name, keep the old one as fallback
for f, old, new in [
    (r"tools\ensure-src.sh",
     'tarball="$ws/../4.4BSD-Lite2.tar.gz"\n[ -f "$tarball" ] || tarball="$ws/4.4BSD-Lite2.tar.gz"',
     'tarball="$ws/../4.5BSD-Lite2.tar.gz"\n[ -f "$tarball" ] || tarball="$ws/4.5BSD-Lite2.tar.gz"\n[ -f "$tarball" ] || tarball="$ws/../4.4BSD-Lite2.tar.gz"\n[ -f "$tarball" ] || tarball="$ws/4.4BSD-Lite2.tar.gz"'),
    (r"tools\ensure-src.sh",
     'if [ -d "$ws/src/4.5BSD-Lite2" ] && [ ! -d "$srcroot" ]; then\n    mv "$ws/src/4.5BSD-Lite2" "$srcroot"',
     'if [ -d "$ws/src/4.5BSD-Lite2" ] && [ ! -d "$srcroot" ]; then\n    mv "$ws/src/4.5BSD-Lite2" "$srcroot"'),
]:
    p = os.path.join(W, f)
    t = rd(p)
    if old in t:
        t = t.replace(old, new)
        wr(p, t)
        print("ensure-src updated")

# ================================================================ 4. kernel/sys from other/kern
k = os.path.join(W, "kernel")
sysdir = os.path.join(k, "sys")
kern = os.path.join(k, "other", "kern")
os.makedirs(sysdir, exist_ok=True)
moved = 0
if os.path.isdir(kern):
    for name in sorted(os.listdir(kern)):
        s = os.path.join(kern, name)
        d = os.path.join(sysdir, name)
        if os.path.isdir(d):
            shutil.rmtree(d)
        elif os.path.exists(d):
            os.remove(d)
        shutil.move(s, d)
        moved += 1
    os.rmdir(kern)
print("moved", moved, "files from other/kern to kernel/sys")

# config.mk comments for the new location
for root, dirs, files in os.walk(k):
    for f in files:
        if f == "config.mk":
            p = os.path.join(root, f)
            t = rd(p)
            if "other/kern" in t:
                t = t.replace("other/kern", "sys")
                wr(p, t)
print("config.mk comments updated")

# build script: add -I "$src" already covers sys/; nothing else references it
print("done")
