# move-libkern.ps1 - rename kernel/lib to kernel/libkern and merge the
# 4.4BSD libkern sources into it.
$ErrorActionPreference = "Stop"
$ws = "C:\Users\Administrator\Desktop\work\bsd45"
$k  = Join-Path $ws "kernel"
$lib = Join-Path $k "lib"
$lk  = Join-Path $k "libkern"
$src = Join-Path $k "other\libkern"

if (Test-Path $lib) {
    if (Test-Path $lk) { Remove-Item $lib -Recurse -Force }
    else { Rename-Item $lib $lk -Force }
}
New-Item -ItemType Directory -Force -Path $lk | Out-Null
if (Test-Path $src) {
    Get-ChildItem $src -Force | ForEach-Object {
        Move-Item $_.FullName (Join-Path $lk $_.Name) -Force
    }
    Remove-Item $src -Recurse -Force -ErrorAction SilentlyContinue
}
# the placeholder is no longer needed
Remove-Item (Join-Path $lk ".keep") -Force -ErrorAction SilentlyContinue

# build_kernel: libkern sources now live in kernel\libkern
$p = Join-Path $ws "build_kernel.ps1"
$t = [IO.File]::ReadAllText($p)
$t = $t.Replace('"$src\other\libkern\bcmp.c"',   '"$src\libkern\bcmp.c"')
$t = $t.Replace('"$src\other\libkern\strcmp.c"', '"$src\libkern\strcmp.c"')
$t = $t.Replace('"$src\other\libkern\strlen.c"', '"$src\libkern\strlen.c"')
$t = $t.Replace('Copy-Item "$src\other\libkern\libkern.h"', 'Copy-Item "$src\libkern\libkern.h"')
[IO.File]::WriteAllText($p, $t, (New-Object System.Text.UTF8Encoding($false)))

# reorganize.ps1: fresh clones put sys\libkern into kernel\libkern
$p = Join-Path $ws "tools\reorganize.ps1"
$t = [IO.File]::ReadAllText($p)
$t = $t.Replace('MoveDir (Join-Path $sys "libkern")       (Join-Path $k "other\libkern")',
                'MoveDir (Join-Path $sys "libkern")       (Join-Path $k "libkern")')
[IO.File]::WriteAllText($p, $t, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "kernel/libkern files: $((Get-ChildItem $lk -File).Count)"
