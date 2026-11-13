# fix-arch.ps1 - 4.5BSD sources include each other as "i386/i386/..." and
# "i386/isa/...", so the arch tree keeps that nesting internally.
$ErrorActionPreference = "Stop"
$ws = "C:\Users\Administrator\Desktop\work\bsd45"
$k  = Join-Path $ws "kernel"
$arch = Join-Path $k "arch\i386"
$inner = Join-Path $arch "i386"

New-Item -ItemType Directory -Force -Path $inner | Out-Null

# move the flat files back into arch/i386/i386 (keep subdirectories at arch/i386)
Get-ChildItem $arch -File -Force | ForEach-Object {
    Move-Item $_.FullName (Join-Path $inner $_.Name) -Force
}

# isa lives under arch/i386 so "i386/isa/icu.s" resolves with -I kernel\arch
$isa = Join-Path $k "driver\isa"
if (Test-Path $isa) {
    if (Test-Path (Join-Path $arch "isa")) { Remove-Item (Join-Path $arch "isa") -Recurse -Force }
    Move-Item $isa (Join-Path $arch "isa") -Force
}
# pci_i386 also arch-specific
$pci = Join-Path $k "driver\pci_i386"
if (Test-Path $pci) {
    if (Test-Path (Join-Path $arch "pci")) { Remove-Item (Join-Path $arch "pci") -Recurse -Force }
    Move-Item $pci (Join-Path $arch "pci") -Force
}

# overlay mirrors the same nesting: overlay/arch/i386/i386/*
$ov = Join-Path $ws "overlay\arch\i386"
if (Test-Path $ov) {
    $ovInner = Join-Path $ov "i386"
    New-Item -ItemType Directory -Force -Path $ovInner | Out-Null
    Get-ChildItem $ov -File -Force | ForEach-Object { Move-Item $_.FullName (Join-Path $ovInner $_.Name) -Force }
}

Write-Host "arch/i386:"
Get-ChildItem $arch -Directory | ForEach-Object { "  $($_.Name)/" }
Write-Host "arch/i386/i386 files: $((Get-ChildItem $inner -File).Count)"
