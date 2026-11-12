# gen-config-mk.ps1 - put a config.mk in every directory of the kernel tree.
#
# The current build driver is build_kernel.ps1; these files are the
# per-directory configuration slots for a future kbuild-style build
# (obj-y/obj-m/dir-y), and they also document what lives where.
param(
    [string]$Root = ""
)

$ErrorActionPreference = "Stop"
if (!$Root) {
    $ws = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
    $Root = Join-Path $ws "kernel"
}
if (!(Test-Path $Root)) { throw "no kernel tree at $Root" }

$count = 0
Get-ChildItem $Root -Directory -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $dir = $_
    $rel = $dir.FullName.Substring($Root.Length).TrimStart('\').Replace('\', '/')

    $sources = @(Get-ChildItem $dir.FullName -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in @('.c', '.s', '.S') } |
        Sort-Object Name | ForEach-Object { $_.Name })
    $subdirs = @(Get-ChildItem $dir.FullName -Directory -Force -ErrorAction SilentlyContinue |
        Sort-Object Name | ForEach-Object { $_.Name })

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# config.mk - kernel/$rel")
    [void]$sb.AppendLine("#")
    [void]$sb.AppendLine("# Per-directory build configuration for the BSD45 kernel.")
    [void]$sb.AppendLine("# build_kernel.ps1 is the current driver; a kbuild-style build can")
    [void]$sb.AppendLine("# pick up obj-y/obj-m/dir-y from here.")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("# obj-y += ")
    [void]$sb.AppendLine("# obj-m += ")
    [void]$sb.AppendLine("# dir-y += ")
    if ($sources.Count -gt 0) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("# sources in this directory:")
        foreach ($s in $sources) { [void]$sb.AppendLine("#   $s") }
    }
    if ($subdirs.Count -gt 0) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("# subdirectories:")
        foreach ($d in $subdirs) { [void]$sb.AppendLine("#   $d/") }
    }

    $path = Join-Path $dir.FullName "config.mk"
    [IO.File]::WriteAllText($path, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    $count++
}
Write-Host "config.mk written in $count directories under $Root"
