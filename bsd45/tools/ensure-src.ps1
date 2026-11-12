# ensure-src.ps1 - make sure the extracted 4.4BSD-Lite2 tree exists.
#
# The tree is regenerated from ../4.4BSD-Lite2.tar.gz; it is deliberately
# not part of the repository (it is huge).  build_sh.ps1 and
# build_kernel.ps1 both call this so either one can run on a fresh clone.
#
# Windows' bsdtar chokes on some symlinks in this tarball, so 7-Zip is
# used when available (it stores them as plain files, which is fine for a
# build) and bsdtar is only the fallback.
param([string]$ws = "")

$ErrorActionPreference = "Stop"
if (!$ws) { $ws = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path) }

$srcroot = Join-Path $ws "src\BSD45"
$marker  = Join-Path $srcroot "usr\src\lib\libc\gen\opendir.c"
if (Test-Path $marker) { return $srcroot }

$tarball = Join-Path $ws "..\4.4BSD-Lite2.tar.gz"
if (!(Test-Path $tarball)) { $tarball = Join-Path $ws "4.4BSD-Lite2.tar.gz" }
if (!(Test-Path $tarball)) {
    throw "4.4BSD-Lite2.tar.gz not found next to the project; put it in the parent directory"
}

Write-Host "extracting $tarball"
$srcdir = Join-Path $ws "src"
New-Item -ItemType Directory -Force -Path $srcdir | Out-Null

# A previous (interrupted) extraction can leave broken symlinks that
# Remove-Item refuses to delete; mirror an empty directory over it first.
if (Test-Path $srcroot) {
    $empty = Join-Path $env:TEMP "dsh-empty-backup"
    New-Item -ItemType Directory -Force -Path $empty | Out-Null
    & robocopy $empty $srcroot /MIR /NFL /NDL /NJH /NJS /R:0 /W:0 | Out-Null
    & $env:ComSpec /c "rmdir /s /q `"$srcroot`"" 2>$null | Out-Null
}

$seven = Join-Path ${env:ProgramFiles(x86)} "VMware\VMware Workstation\7za.exe"
if (!(Test-Path $seven)) { $seven = "7za.exe" }

if (Test-Path $seven) {
    & $seven x -y "-o$srcdir" $tarball | Out-Null
    $tarfile = Get-ChildItem $srcdir -Filter *.tar | Select-Object -First 1
    if ($tarfile) {
        & $seven x -y -ttar "-o$srcdir" $tarfile.FullName | Out-Null
        Remove-Item $tarfile.FullName -Force -ErrorAction SilentlyContinue
    }
} else {
    $tarExe = Join-Path $env:SystemRoot "System32\tar.exe"
    & $tarExe -xzf $tarball -C $srcdir 2>$null
}

$extracted = Join-Path $srcdir "4.4BSD-Lite2"
if ((Test-Path $extracted) -and !(Test-Path $srcroot)) {
    Rename-Item $extracted $srcroot -Force
}
& $env:ComSpec /c "attrib -R `"$srcroot\*.*`" /S /D" 2>$null | Out-Null
if (!(Test-Path (Join-Path $ws "kernel\arch\i386\i386\locore.s"))) {
    & (Join-Path $ws "tools\reorganize.ps1")
}
if (!(Test-Path $marker)) { throw "extraction failed: $marker missing" }
return $srcroot
