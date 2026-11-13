# move-libkern.ps1 - one-time helper: kernel\libkern was renamed to kernel\lib.
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
