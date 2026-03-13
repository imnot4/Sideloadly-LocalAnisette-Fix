[CmdletBinding()]
param(
    [string]$Version = "v1.0.0",
    [switch]$KeepStage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Path $PSCommandPath -Parent
$projectDir = Split-Path -Path $scriptDir -Parent
$distDir = Join-Path $projectDir "dist"
New-Item -Path $distDir -ItemType Directory -Force | Out-Null

$safeVersion = ($Version -replace "[^a-zA-Z0-9\.\-_]", "_")
$releaseName = "Sideloadly-LocalAnisette-Fix-{0}" -f $safeVersion
$stageDir = Join-Path $distDir $releaseName
$zipPath = Join-Path $distDir ("{0}.zip" -f $releaseName)
$hashFile = Join-Path $distDir ("{0}-SHA256SUMS.txt" -f $releaseName)
$signatureFile = Join-Path $distDir ("{0}-SIGNATURES.txt" -f $releaseName)

if (Test-Path $stageDir) { Remove-Item -Path $stageDir -Recurse -Force }
if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force }
if (Test-Path $hashFile) { Remove-Item -Path $hashFile -Force }
if (Test-Path $signatureFile) { Remove-Item -Path $signatureFile -Force }

New-Item -Path $stageDir -ItemType Directory -Force | Out-Null

$includeFiles = @(
    "README.md",
    "README_RU.md",
    "Fix-Sideloadly-LocalAnisette.ps1",
    "Show-SupportPrompt.ps1",
    "support-config.json",
    "Run-Fix.cmd",
    "Run-Fix-Admin.cmd",
    "Start-Here.cmd",
    "Start-Sideloadly-Fixed.cmd"
)

foreach ($file in $includeFiles) {
    $source = Join-Path $projectDir $file
    if (-not (Test-Path $source)) {
        throw ("Missing file for release: {0}" -f $source)
    }
    $destination = Join-Path $stageDir $file
    $destinationDir = Split-Path -Path $destination -Parent
    if (-not (Test-Path $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path $source -Destination $destination -Force
}

Compress-Archive -Path (Join-Path $stageDir "*") -DestinationPath $zipPath -CompressionLevel Optimal

$hashLines = @()
Get-ChildItem -Path $stageDir -File | Sort-Object Name | ForEach-Object {
    $hash = Get-FileHash -Path $_.FullName -Algorithm SHA256
    $hashLines += ("{0}  {1}" -f $hash.Hash.ToLowerInvariant(), $_.Name)
}
$zipHash = Get-FileHash -Path $zipPath -Algorithm SHA256
$hashLines += ("{0}  {1}" -f $zipHash.Hash.ToLowerInvariant(), (Split-Path $zipPath -Leaf))
$hashLines | Set-Content -Path $hashFile -Encoding ASCII

$sigLines = @()
Get-ChildItem -Path $stageDir -File | Where-Object { $_.Extension -in @(".ps1", ".cmd") } | Sort-Object Name | ForEach-Object {
    $sig = Get-AuthenticodeSignature -FilePath $_.FullName
    $sigLines += ("{0}`t{1}" -f $_.Name, $sig.Status)
}
$sigLines | Set-Content -Path $signatureFile -Encoding UTF8

if (-not $KeepStage -and (Test-Path $stageDir)) {
    Remove-Item -Path $stageDir -Recurse -Force
}

Write-Host "Release created:"
Write-Host $zipPath
Write-Host $hashFile
Write-Host $signatureFile
