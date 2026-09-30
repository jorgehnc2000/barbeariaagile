# One-time per clone: enable shared git hooks + verify remotes.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

git config core.hooksPath .githooks
Write-Host "Git hooks path set to .githooks (auto-push after commit)."

$remote = git remote get-url origin 2>$null
if ($remote) {
  Write-Host "Remote origin: $remote"
} else {
  Write-Warning "No origin remote. Add GitHub before auto-sync can push."
}
