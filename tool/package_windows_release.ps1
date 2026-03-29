param(
  [string]$OutputDir = "dist\windows\orders"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$releaseDir = Join-Path $repoRoot "build\windows\x64\runner\Release"
$targetDir = Join-Path $repoRoot $OutputDir

Write-Host "Building Windows release..."
Push-Location $repoRoot
try {
  flutter build windows --release
} finally {
  Pop-Location
}

if (-not (Test-Path $releaseDir)) {
  throw "Release build output not found at $releaseDir"
}

if (Test-Path $targetDir) {
  Remove-Item -LiteralPath $targetDir -Recurse -Force
}

New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
Copy-Item -Path (Join-Path $releaseDir "*") -Destination $targetDir -Recurse -Force

$launcherPath = Join-Path $targetDir "orders.exe"
if (-not (Test-Path $launcherPath)) {
  throw "orders.exe was not found in $targetDir"
}

Write-Host ""
Write-Host "Portable Windows package created:"
Write-Host "  $targetDir"
Write-Host ""
Write-Host "Share the whole folder, not only orders.exe."
