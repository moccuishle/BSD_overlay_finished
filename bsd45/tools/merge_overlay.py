import io, os, shutil

W = r"C:\Users\Administrator\Desktop\work\bsd45"
ov = os.path.join(W, "overlay", "arch", "i386", "i386")
isa = os.path.join(W, "kernel", "arch", "i386", "isa")

os.makedirs(isa, exist_ok=True)
for name in ("locore.s", "machdep.c", "pmap.c"):
    src = os.path.join(ov, name)
    dst = os.path.join(isa, name)
    if os.path.exists(src):
        shutil.copy2(src, dst)
        print("merged", name, "->", dst)

# build_kernel: compile the patched files from isa/, drop the overlay copy
p = os.path.join(W, "build_kernel.ps1")
t = io.open(p, encoding="utf-8", newline="").read().replace("\r\n", "\n")
t = t.replace('"$src\\arch\\i386\\i386\\locore.s"',  '"$src\\arch\\i386\\isa\\locore.s"')
t = t.replace('"$src\\arch\\i386\\i386\\pmap.c"',    '"$src\\arch\\i386\\isa\\pmap.c"')
t = t.replace('"$src\\arch\\i386\\i386\\machdep.c"', '"$src\\arch\\i386\\isa\\machdep.c"')

old = '''$overlay = Join-Path $ws "overlay"
if (Test-Path $overlay) {
    Copy-Item "$overlay\\*" $src -Recurse -Force
}
'''
if old in t:
    t = t.replace(old, "")
    print("overlay copy step removed")

io.open(p, "w", encoding="utf-8", newline="\n").write(t)

# delete overlay/arch/i386/i386 and any now-empty parents
ovroot = os.path.join(W, "overlay")
shutil.rmtree(os.path.join(ovroot, "arch"), ignore_errors=True)
if os.path.isdir(ovroot) and not os.listdir(ovroot):
    os.rmdir(ovroot)
    print("overlay/ removed (empty)")

# .gitignore: keep the three patched files tracked inside the ignored arch tree
p = r"C:\Users\Administrator\Desktop\work\.gitignore"
t = io.open(p, encoding="utf-8", newline="").read()
if "kernel/arch/i386/isa/locore.s" not in t:
    extra = """
# the three patched 4.4BSD files live in kernel/arch/i386/isa but stay tracked
bsd45/kernel/arch/*
!bsd45/kernel/arch/i386/
bsd45/kernel/arch/i386/*
!bsd45/kernel/arch/i386/isa/
bsd45/kernel/arch/i386/isa/*
!bsd45/kernel/arch/i386/isa/locore.s
!bsd45/kernel/arch/i386/isa/machdep.c
!bsd45/kernel/arch/i386/isa/pmap.c
"""
    # the broad "bsd45/kernel/arch/" ignore comes earlier; add the refined rules after it
    t = t.replace("bsd45/kernel/arch/\n", extra)
    io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("gitignore rules ok")
