# test_s8.ps1 - S8 acceptance: tmpfs, redirection and mkdir.
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

Write-Host "S8 acceptance: tmpfs + redirection"
$log = (& $script -Iso $Iso -Keys @(
    "shell",
    "echo hello-tmpfs > /tmp/a",
    "cat /tmp/a",
    "echo second >> /tmp/a",
    "cat /tmp/a",
    "mkdir /tmp/d",
    "ls /tmp",
    "exit 0") -WaitFor "user exit" -TimeoutSec 60) -join "`n"

Check "write"  $log @("hello-tmpfs")
Check "append" $log @("second")
Check "mkdir"  $log @("d")
Check "ls"     $log @("a")
Check "exit"   $log @("[user exit 0]")
if ($log -match 'TRAP') {
    Write-Host "  FAIL kernel trap" -ForegroundColor Red
    $fails++
}
if ($log -match 'No such file') {
    Write-Host "  FAIL unexpected ENOENT" -ForegroundColor Red
    $fails++
}

if ($fails) {
    Write-Host "`nS8: FAILED ($fails)" -ForegroundColor Red
    exit 1
}
Write-Host "`nS8: PASSED" -ForegroundColor Green
exit 0
