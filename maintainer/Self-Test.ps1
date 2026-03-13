[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Path $PSCommandPath -Parent
$projectDir = Split-Path -Path $scriptDir -Parent
$fixScript = Join-Path $projectDir "Fix-Sideloadly-LocalAnisette.ps1"
$supportConfig = Join-Path $projectDir "support-config.json"
$runsDir = Join-Path $projectDir "runs"

$requiredFiles = @(
    "Start-Here.cmd",
    "Run-Fix.cmd",
    "Run-Fix-Admin.cmd",
    "Fix-Sideloadly-LocalAnisette.ps1",
    "Show-SupportPrompt.ps1",
    "support-config.json",
    "README.md",
    "README_RU.md"
)

$errors = @()
$warnings = @()

foreach ($file in $requiredFiles) {
    if (-not (Test-Path (Join-Path $projectDir $file))) {
        $errors += "Missing required file: $file"
    }
}

if (-not (Test-Path $fixScript)) {
    $errors += "Fix script not found."
}
else {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $fixScript -NoLaunch -SkipAnisetteRedownload -SkipAdiReset -SkipCertificateFix | Out-Host
    if ($LASTEXITCODE -ne 0) {
        $errors += "Fix script dry run failed with exit code $LASTEXITCODE."
    }
}

if (Test-Path $runsDir) {
    $latestRun = Get-ChildItem -Path $runsDir -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -ne $latestRun) {
        $reportPath = Join-Path $latestRun.FullName "report.json"
        if (Test-Path $reportPath) {
            $report = Get-Content -Path $reportPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if (@($report.errors).Count -gt 0) {
                $errors += "Report contains errors: $($report.errors -join '; ')"
            }
        }
        else {
            $errors += "report.json not found in latest run folder."
        }
    }
    else {
        $warnings += "No run folders found after dry run."
    }
}

if (Test-Path $supportConfig) {
    $cfg = Get-Content -Path $supportConfig -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace([string]$cfg.url) -or [string]$cfg.url -eq "https://example.com/donate") {
        $warnings += "support-config.json still uses placeholder donation URL."
    }
}
else {
    $errors += "support-config.json not found."
}

Write-Host ""
Write-Host "Self-test summary:"
Write-Host ("Errors: {0}" -f @($errors).Count)
Write-Host ("Warnings: {0}" -f @($warnings).Count)

if (@($warnings).Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings:"
    $warnings | ForEach-Object { Write-Host (" - {0}" -f $_) }
}

if (@($errors).Count -gt 0) {
    Write-Host ""
    Write-Host "Errors:"
    $errors | ForEach-Object { Write-Host (" - {0}" -f $_) }
    exit 1
}

Write-Host ""
Write-Host "PASS"
exit 0
