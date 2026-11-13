import io, os, shutil, re

W = r"C:\Users\Administrator\Desktop\work\bsd45"

def rd(p):
    return io.open(p, encoding="utf-8", errors="surrogateescape", newline="").read().replace("\r\n", "\n")

def wr(p, t):
    io.open(p, "w", encoding="utf-8", errors="surrogateescape", newline="\n").write(t)

# ---------------------------------------------------------------- rename dirs
renames = [
    (os.path.join(W, "kernel", "libkern"), os.path.join(W, "kernel", "lib")),
    (os.path.join(W, "kernel", "include", "libkern"), os.path.join(W, "kernel", "include", "lib")),
]
for src, dst in renames:
    if os.path.isdir(src):
        if os.path.isdir(dst):
            # merge then remove
            for name in os.listdir(src):
                s, d = os.path.join(src, name), os.path.join(dst, name)
                if os.path.exists(d):
                    shutil.rmtree(d) if os.path.isdir(d) else os.remove(d)
                shutil.move(s, d)
            os.rmdir(src)
        else:
            shutil.move(src, dst)
        print("renamed", src, "->", dst)

# ---------------------------------------------------------------- C includes
count = 0
for root, dirs, files in os.walk(W):
    if os.sep + "src" + os.sep in root + os.sep or "\\build\\" in root or "\\out\\" in root:
        continue
    for f in files:
        if not f.endswith((".c", ".h")):
            continue
        p = os.path.join(root, f)
        t = rd(p)
        if "#include <libkern/" in t or '#include "libkern/' in t:
            t = t.replace("#include <libkern/", "#include <lib/").replace('#include "libkern/', '#include "lib/')
            wr(p, t)
            count += 1
print("include lines updated in", count, "files")

# ---------------------------------------------------------------- scripts/docs
def sub(path, pairs):
    if not os.path.exists(path):
        return
    t = rd(path)
    orig = t
    for a, b in pairs:
        t = t.replace(a, b)
    if t != orig:
        wr(path, t)
        print("updated", os.path.basename(path))

for f in ("build_kernel.sh", "build_kernel.ps1", "build_sh.sh", "build_all.sh", "build_all.ps1"):
    sub(os.path.join(W, f), [
        ("kernel/libkern", "kernel/lib"),
        ("kernel\\libkern", "kernel\\lib"),
        ("$src/libkern", "$src/lib"),
        ("$src\\libkern", "$src\\lib"),
        ("$ws/kernel/libkern", "$ws/kernel/lib"),
        ("inc/libkern", "inc/lib"),
        ("include/libkern", "include/lib"),
        ("include\\libkern", "include\\lib"),
    ])

for f in ("README.md", "LINUX-BUILD.md"):
    sub(os.path.join(W, f), [
        ("kernel/libkern", "kernel/lib"),
        ("kernel/include/libkern", "kernel/include/lib"),
        ("kernel\\libkern", "kernel\\lib"),
    ])

sub(os.path.join(W, "tools", "reorganize.sh"), [("$k/libkern", "$k/lib")])
sub(os.path.join(W, "tools", "reorganize.ps1"), [("$k\\libkern", "$k\\lib")])

# .gitignore rules for the header directory
sub(r"C:\Users\Administrator\Desktop\work\.gitignore", [
    ("bsd45/kernel/include/libkern/", "bsd45/kernel/include/lib/"),
])

# config.mk comments
for root, dirs, files in os.walk(os.path.join(W, "kernel")):
    for f in files:
        if f == "config.mk":
            p = os.path.join(root, f)
            t = rd(p)
            if "libkern" in t:
                t = t.replace("kernel/include/libkern", "kernel/include/lib").replace("kernel/libkern", "kernel/lib").replace("libkern/", "lib/")
                wr(p, t)
print("config.mk comments updated")

# move-libkern helper now performs the libkern -> lib rename
move_sh = r'''#!/usr/bin/env bash
# move-libkern.sh - one-time helper: kernel/libkern was renamed to kernel/lib.
# Idempotent: renames the directory and the header dir, rewrites references.
set -uo pipefail
ws="$(cd "$(dirname "$0")/.." && pwd)"
k="$ws/kernel"

if [ -d "$k/libkern" ] && [ ! -d "$k/lib" ]; then
    mv "$k/libkern" "$k/lib"
    echo "kernel/libkern -> kernel/lib"
fi
if [ -d "$k/include/libkern" ] && [ ! -d "$k/include/lib" ]; then
    mv "$k/include/libkern" "$k/include/lib"
    echo "kernel/include/libkern -> kernel/include/lib"
fi

grep -rl '#include <libkern/' "$k" 2>/dev/null | while read -r f; do
    sed -i 's|#include <libkern/|#include <lib/|g' "$f"
done
echo "kernel/lib files: $(find "$k/lib" -maxdepth 1 -type f 2>/dev/null | wc -l)"
'''
wr(os.path.join(W, "tools", "move-libkern.sh"), move_sh)
print("move-libkern.sh rewritten")

move_ps1 = r'''# move-libkern.ps1 - one-time helper: kernel\libkern was renamed to kernel\lib.
$ErrorActionPreference = "Stop"
$ws = Split-Path -Parent $PSScriptRoot
$k = Join-Path $ws "kernel"

foreach ($pair in @(@("libkern", "lib"), @("include\libkern", "include\lib"))) {
    $src = Join-Path $k $pair[0]
    $dst = Join-Path $k $pair[1]
    if ((Test-Path $src) -and !(Test-Path $dst)) {
        Move-Item $src $dst
        "moved $($pair[0]) -> $($pair[1])"
    }
}
Get-ChildItem -Path $k -Recurse -Include *.c,*.h |
    Where-Object { (Get-Content $_.FullName -Raw) -match '#include <libkern/' } |
    ForEach-Object {
        (Get-Content $_.FullName -Raw).Replace('#include <libkern/', '#include <lib/') |
            Set-Content $_.FullName -NoNewline
    }
'''
wr(os.path.join(W, "tools", "move-libkern.ps1"), move_ps1)
print("move-libkern.ps1 rewritten")
