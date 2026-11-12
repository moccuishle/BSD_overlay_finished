import io, re

W = r"C:\Users\Administrator\Desktop\work\bsd45"

# ---------------------------------------------------------------- kernel build
p = W + r"\build_kernel.ps1"
t = io.open(p, encoding="utf-8", newline="").read().replace("\r\n", "\n")

t = t.replace('$src  = Join-Path $ws "src\\BSD45\\usr\\src\\sys"',
              '$src  = Join-Path $ws "kernel"')

t = t.replace('Copy-Headers "$src\\sys" "$inc\\sys"',        'Copy-Headers "$src\\include\\sys" "$inc\\sys"')
t = t.replace('Copy-Headers "$src\\i386\\include" "$inc\\machine"', 'Copy-Headers "$src\\include\\machine" "$inc\\machine"')
t = t.replace('Copy-Headers "$src\\i386\\include" "$inc\\i386"',    'Copy-Headers "$src\\include\\machine" "$inc\\i386"')
t = t.replace('Copy-Item "$src\\hp300\\include\\ansi.h"  "$inc\\machine\\ansi.h"  -Force',
              'Copy-Item "$src\\include\\machine\\ansi.h"  "$inc\\machine\\ansi.h"  -Force')
t = t.replace('Copy-Item "$src\\hp300\\include\\limits.h" "$inc\\machine\\limits.h" -Force',
              'Copy-Item "$src\\include\\machine\\limits.h" "$inc\\machine\\limits.h" -Force')
t = t.replace('Copy-Item "$src\\hp300\\include\\float.h"  "$inc\\machine\\float.h"  -Force',
              'Copy-Item "$src\\include\\machine\\float.h"  "$inc\\machine\\float.h"  -Force')
t = t.replace('Copy-Item "$src\\libkern\\libkern.h" "$inc\\libkern\\libkern.h" -Force',
              'Copy-Item "$src\\other\\libkern\\libkern.h" "$inc\\libkern\\libkern.h" -Force')
t = t.replace('"$src\\i386\\i386\\genassym.c"', '"$src\\arch\\i386\\genassym.c"')

t = t.replace('"locore.o"   = @("asm", "$src\\i386\\i386\\locore.s")',
              '"locore.o"   = @("asm", "$src\\arch\\i386\\locore.s")')
for name in ("pmap", "machdep", "cons"):
    t = t.replace(f'"{name}.o"     = @("c",   "$src\\i386\\i386\\{name}.c")',
                  f'"{name}.o"     = @("c",   "$src\\arch\\i386\\{name}.c")')
for name in ("bcmp", "strcmp", "strlen"):
    t = t.replace(f'"{name}.o"     = @("c",   "$src\\libkern\\{name}.c")',
                  f'"{name}.o"     = @("c",   "$src\\other\\libkern\\{name}.c")')

t = t.replace('"strings.o"  = @("c",   "$ws\\kernel\\strings.c")',
              '"strings.o"  = @("c",   "$ws\\kernel\\other\\strings.c")')
t = t.replace('"usermode.o" = @("c",   "$ws\\kernel\\usermode.c")',
              '"usermode.o" = @("c",   "$ws\\kernel\\other\\usermode.c")')
t = t.replace('"usermode_asm.o" = @("asm", "$ws\\kernel\\usermode_asm.s")',
              '"usermode_asm.o" = @("asm", "$ws\\kernel\\other\\usermode_asm.s")')
t = t.replace('"pccon.o"    = @("c",   "$ws\\kernel\\pccon.c")',
              '"pccon.o"    = @("c",   "$ws\\kernel\\driver\\pccon.c")')
t = t.replace('"stubs.o"    = @("c",   "$ws\\kernel\\stubs.c")',
              '"stubs.o"    = @("c",   "$ws\\kernel\\other\\stubs.c")')
t = t.replace('"glue.o"     = @("c",   "$ws\\kernel\\glue.c")',
              '"glue.o"     = @("c",   "$ws\\kernel\\other\\glue.c")')
t = t.replace('"mon.o"      = @("c",   "$ws\\kernel\\mon.c")',
              '"mon.o"      = @("c",   "$ws\\kernel\\other\\mon.c")')
t = t.replace('"atapi.o"    = @("c",   "$ws\\kernel\\atapi.c")',
              '"atapi.o"    = @("c",   "$ws\\kernel\\driver\\atapi.c")')
t = t.replace('"isofs.o"    = @("c",   "$ws\\kernel\\isofs.c")',
              '"isofs.o"    = @("c",   "$ws\\kernel\\fs\\isofs.c")')
t = t.replace('"vfs.o"      = @("c",   "$ws\\kernel\\vfs.c")',
              '"vfs.o"      = @("c",   "$ws\\kernel\\fs\\vfs.c")')

io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("build_kernel paths ok")

# ---------------------------------------------------------------- sh/userland
p = W + r"\build_sh.ps1"
t = io.open(p, encoding="utf-8", newline="").read()
t = t.replace('Join-Path $ws "userland\\include\\stdarg.h"', 'Join-Path $ws "libc\\include\\stdarg.h"')
t = t.replace('Join-Path $ws "userland\\libc\\ctype.h"',     'Join-Path $ws "libc\\include\\ctype.h"')
t = t.replace('Join-Path $ws "userland\\libc\\histedit.h"',  'Join-Path $ws "libc\\include\\histedit.h"')
t = t.replace('Join-Path $ws "userland\\libc\\crt0.s"',      'Join-Path $ws "libc\\src\\crt0.s"')
t = t.replace('Join-Path $ws "userland\\libc\\jmp.s"',       'Join-Path $ws "libc\\src\\jmp.s"')
t = t.replace('Join-Path $ws "userland\\libc\\libc_sys.c"',  'Join-Path $ws "libc\\src\\libc_sys.c"')
t = t.replace('Join-Path $ws "userland\\libc\\dtoa.c"',      'Join-Path $ws "libc\\src\\dtoa.c"')
t = t.replace('Join-Path $ws "userland\\libc\\histedit_stub.c"', 'Join-Path $ws "libc\\src\\histedit_stub.c"')
t = t.replace('Join-Path $ws "userland\\libc\\errlst.c"',    'Join-Path $ws "libc\\src\\errlst.c"')
t = t.replace('Join-Path $ws "userland\\libc\\ctype_table.c"', 'Join-Path $ws "libc\\src\\ctype_table.c"')
t = t.replace('"userland\\libc\\*"', '"libc\\src\\*"')
t = t.replace('Join-Path $ws "userland\\hostgen\\hostshim.h"', 'Join-Path $ws "libc\\src\\hostgen\\hostshim.h"')
t = t.replace('Join-Path $ws "userland\\hostgen\\mknodes.c"',  'Join-Path $ws "libc\\src\\hostgen\\mknodes.c"')
t = t.replace('Join-Path $ws "userland\\hostgen\\hoststub.c"', 'Join-Path $ws "libc\\src\\hostgen\\hoststub.c"')
t = t.replace('Join-Path $ws "userland\\t_libc.c"', 'Join-Path $ws "libc\\src\\t_libc.c"')
t = t.replace('Join-Path $ws "userland\\$tool.c"', 'Join-Path $ws "libc\\src\\$tool.c"')
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("build_sh paths ok")

p = W + r"\build_userland.ps1"
t = io.open(p, encoding="utf-8", newline="").read()
t = t.replace('Join-Path $ws "userland\\hello.c"', 'Join-Path $ws "libc\\src\\hello.c"')
t = t.replace('Join-Path $ws "userland\\init.c"',  'Join-Path $ws "libc\\src\\init.c"')
t = t.replace('Join-Path $ws "userland\\sh.c"',    'Join-Path $ws "libc\\src\\sh.c"')
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("build_userland paths ok")

# ---------------------------------------------------------------- .gitignore
p = r"C:\Users\Administrator\Desktop\work\.gitignore"
t = io.open(p, encoding="utf-8", newline="").read()
extra = """
# 4.4BSD-Lite2 tree, merged into kernel/ but not tracked (regenerated from
# the tarball by tools/ensure-src.ps1 + tools/layout-sys.ps1)
bsd45/kernel/include/sys/
bsd45/kernel/include/machine/
bsd45/kernel/include/libkern/
bsd45/kernel/arch/
bsd45/kernel/vm/
bsd45/kernel/net/
bsd45/kernel/fs/ufs/
bsd45/kernel/fs/miscfs/
bsd45/kernel/fs/isofs/
bsd45/kernel/fs/nfs/
bsd45/kernel/driver/dev/
bsd45/kernel/driver/isa/
bsd45/kernel/driver/pci_i386/
bsd45/kernel/other/kern/
bsd45/kernel/other/conf/
bsd45/kernel/other/compile/
bsd45/kernel/other/libkern/
bsd45/kernel/other/scripts/
bsd45/kernel/other/stand/
bsd45/kernel/other/stand.att/
bsd45/kernel/other/tests/
bsd45/kernel/other/mips
"""
if "kernel/include/sys" not in t:
    t = t.rstrip() + "\n" + extra
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("gitignore ok")
