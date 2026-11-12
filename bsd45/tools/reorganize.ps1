# reorganize.ps1 - move the 4.4BSD sys tree and userland into a Linux-like
# layout under bsd45/kernel and bsd45/libc.
$ErrorActionPreference = "Stop"
$ws = "C:\Users\Administrator\Desktop\work\bsd45"
$sys = Join-Path $ws "src\BSD45\usr\src\sys"
$k   = Join-Path $ws "kernel"

function Ensure($p) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
function MoveDir($src, $dst) {
    if (!(Test-Path $src)) { Write-Host "  skip (missing): $src"; return }
    Ensure (Split-Path -Parent $dst)
    if (Test-Path $dst) { Write-Host "  MERGE $src -> $dst"; Get-ChildItem $src -Force | ForEach-Object { Move-Item $_.FullName (Join-Path $dst $_.Name) -Force } }
    else { Move-Item $src $dst -Force }
    Write-Host "  $([IO.Path]::GetFileName($src)) -> $($dst.Replace($ws+'\',''))"
}

# ---------------- kernel tree
Ensure (Join-Path $k "include\sys"); Ensure (Join-Path $k "include\machine")
Ensure (Join-Path $k "include\libkern")
Ensure (Join-Path $k "arch"); Ensure (Join-Path $k "fs"); Ensure (Join-Path $k "vm")
Ensure (Join-Path $k "driver"); Ensure (Join-Path $k "net"); Ensure (Join-Path $k "other")

MoveDir (Join-Path $sys "sys")            (Join-Path $k "include\sys")
MoveDir (Join-Path $sys "i386\include")   (Join-Path $k "include\machine")

# architecture trees
MoveDir (Join-Path $sys "i386\i386")      (Join-Path $k "arch\i386")
foreach ($a in @("hp","hp300","luna68k","news3400","pmax","sparc","tahoe","vax")) {
    MoveDir (Join-Path $sys $a) (Join-Path $k "arch\$a")
}
MoveDir (Join-Path $sys "i386\conf")      (Join-Path $k "arch\i386\conf")
foreach ($d in (Get-ChildItem (Join-Path $sys "i386") -Directory -ErrorAction SilentlyContinue)) {
    if ($d.Name -in @("include","i386","conf","isa","pci")) { continue }
    MoveDir $d.FullName (Join-Path $k "arch\i386\$($d.Name)")
}

# subsystems
foreach ($d in @("ufs","miscfs","isofs","msdosfs","nfs")) {
    MoveDir (Join-Path $sys $d) (Join-Path $k "fs\$d")
}
MoveDir (Join-Path $sys "vm")             (Join-Path $k "vm")
MoveDir (Join-Path $sys "dev")            (Join-Path $k "driver\dev")
MoveDir (Join-Path $sys "i386\isa")       (Join-Path $k "driver\isa")
MoveDir (Join-Path $sys "i386\pci")       (Join-Path $k "driver\pci_i386")
foreach ($d in @("net","netccitt","netinet","netiso","netns")) {
    MoveDir (Join-Path $sys $d) (Join-Path $k "net\$d")
}
MoveDir (Join-Path $sys "libkern") (Join-Path $k "libkern")
foreach ($d in @("kern","conf","compile","scripts","stand","stand.att","tests")) {
    MoveDir (Join-Path $sys $d) (Join-Path $k "other\$d")
}
Get-ChildItem $sys -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
    Move-Item $_.FullName (Join-Path $k "other\$($_.Name)") -Force
}
# hp300 headers used by the build
if (Test-Path (Join-Path $k "arch\hp300\include")) {
    Copy-Item (Join-Path $k "arch\hp300\include\ansi.h")   (Join-Path $k "include\machine\ansi.h")   -Force
    Copy-Item (Join-Path $k "arch\hp300\include\limits.h") (Join-Path $k "include\machine\limits.h") -Force
    Copy-Item (Join-Path $k "arch\hp300\include\float.h")  (Join-Path $k "include\machine\float.h")  -Force
}
# libkern header next to its sources
if (Test-Path (Join-Path $k "libkern\libkern.h")) {
    Copy-Item (Join-Path $k "libkern\libkern.h") (Join-Path $k "include\libkern\libkern.h") -Force
}

# ---------------- project kernel files
MoveDir (Join-Path $k "usermode.c")      (Join-Path $k "other\usermode.c")
MoveDir (Join-Path $k "usermode_asm.s")  (Join-Path $k "other\usermode_asm.s")
MoveDir (Join-Path $k "glue.c")          (Join-Path $k "other\glue.c")
MoveDir (Join-Path $k "mon.c")           (Join-Path $k "other\mon.c")
MoveDir (Join-Path $k "stubs.c")         (Join-Path $k "other\stubs.c")
MoveDir (Join-Path $k "strings.c")       (Join-Path $k "other\strings.c")
MoveDir (Join-Path $k "vfs.c")           (Join-Path $k "fs\vfs.c")
MoveDir (Join-Path $k "vfs.h")           (Join-Path $k "fs\vfs.h")
MoveDir (Join-Path $k "isofs.c")         (Join-Path $k "fs\isofs.c")
MoveDir (Join-Path $k "isofs.h")         (Join-Path $k "fs\isofs.h")
MoveDir (Join-Path $k "atapi.c")         (Join-Path $k "driver\atapi.c")
MoveDir (Join-Path $k "atapi.h")         (Join-Path $k "driver\atapi.h")
MoveDir (Join-Path $k "pccon.c")         (Join-Path $k "driver\pccon.c")

# ---------------- overlay mirrors the new kernel tree
$ov = Join-Path $ws "overlay"
$ovNew = Join-Path $ws "overlay-new"
if (Test-Path (Join-Path $ov "i386\i386")) {
    Ensure (Join-Path $ovNew "arch\i386")
    Get-ChildItem (Join-Path $ov "i386\i386") -File -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $ovNew "arch\i386\$($_.Name)") -Force
    }
    Remove-Item $ov -Recurse -Force
    Move-Item $ovNew $ov
}

# ---------------- libc tree
$lc = Join-Path $ws "libc"
Ensure (Join-Path $lc "include"); Ensure (Join-Path $lc "src")
$ul = Join-Path $ws "userland"
MoveDir (Join-Path $ul "include\stdarg.h") (Join-Path $lc "include\stdarg.h")
MoveDir (Join-Path $ul "libc\ctype.h")     (Join-Path $lc "include\ctype.h")
MoveDir (Join-Path $ul "libc\histedit.h")  (Join-Path $lc "include\histedit.h")
foreach ($f in (Get-ChildItem (Join-Path $ul "libc") -File -Force)) {
    MoveDir $f.FullName (Join-Path $lc "src\$($f.Name)")
}
foreach ($f in (Get-ChildItem $ul -File -Force -ErrorAction SilentlyContinue)) {
    MoveDir $f.FullName (Join-Path $lc "src\$($f.Name)")
}
MoveDir (Join-Path $ul "hostgen") (Join-Path $lc "src\hostgen")
if (Test-Path $ul) { Remove-Item $ul -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "`n=== kernel ==="
Get-ChildItem $k -Directory | ForEach-Object { "  $($_.Name)/" }
Write-Host "=== libc ==="
Get-ChildItem $lc -Directory | ForEach-Object { "  $($_.Name)/" }

# every directory gets its config.mk
& (Join-Path $ws "tools\gen-config-mk.ps1") -Root (Join-Path $k "")
