# test_s9.ps1 - S9 acceptance: one vnode/VFS layer over ISO9660 and tmpfs.
param([string]$Iso = "")

$ErrorActionPreference = "Stop"
$ws = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (!$Iso) { $Iso = Join-Path $ws "out\BSD45-ELF-x86.iso" }

$script = Join-Path $ws "tools\run_qemu_test.ps1"
$fails = 0

function Check([string]$name, [string]$log, [string[]]$needles) {
    foreach ($n in $needles) {
        if ($log.Contains($n)) {
            Write-Host ("  ok   {0}: found {1}" -f $name, $n) -ForegroundColor Green
        } else {
            Write-Host ("  FAIL {0}: missing {1}" -f $name, $n) -ForegroundColor Red
            $script:fails++
        }
    }
}

Write-Host "S9 acceptance: vnode/VFS over ISO9660 + tmpfs"
$log = (& $script -Iso $Iso -Keys @(
    "shell",
    "ls /",
    "ls /tmp",
    "cat /readme.txt",
    "echo vfs-ok > /tmp/a",
    "cat /tmp/a",
    "mkdir /tmp/d",
    "ls /tmp",
    "echo hi-vfs | cat",
    "exit 0") -WaitFor "user exit" -TimeoutSec 60) -join "`n"

Check "iso dir"   $log @("bin", "sbin", "readme.txt")
Check "iso file"  $log @("via vnode", "boot.img")
Check "tmpfs dir" $log @("a", "d")
Check "tmpfs file" $log @("vfs-ok")
Check "pipe"      $log @("hi-vfs")
Check "exit"      $log @("[user exit 0]")
if ($log -match 'TRAP') {
    Write-Host "  FAIL kernel trap" -ForegroundColor Red
    $fails++
}

if ($fails) {
    Write-Host "`nS9: FAILED ($fails)" -ForegroundColor Red
    exit 1
}
Write-Host "`nS9: PASSED" -ForegroundColor Green
exit 0
