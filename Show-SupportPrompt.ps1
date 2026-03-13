[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path (Split-Path -Path $PSCommandPath -Parent) "support-config.json"),
    [string]$StatePath = (Join-Path (Split-Path -Path $PSCommandPath -Parent) ".support-dismissed")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try {
    if (-not (Test-Path $ConfigPath)) {
        exit 0
    }

    $cfg = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $cfg.enabled) {
        exit 0
    }

    if ([bool]$cfg.allow_dismiss -and (Test-Path $StatePath)) {
        exit 0
    }

    $title = if ([string]::IsNullOrWhiteSpace($cfg.title)) { "Support the project" } else { [string]$cfg.title }
    $message = @"
$($cfg.message)

Support link:
$($cfg.url)

Yes = open link
No = close
"@

    Add-Type -AssemblyName PresentationFramework
    $result = [System.Windows.MessageBox]::Show($message, $title, "YesNo", "Information")

    if ($result -eq "Yes" -and -not [string]::IsNullOrWhiteSpace([string]$cfg.url)) {
        Start-Process -FilePath ([string]$cfg.url) | Out-Null
    }

    if ([bool]$cfg.allow_dismiss) {
        $dismissAsk = if ([string]::IsNullOrWhiteSpace([string]$cfg.dismiss_prompt)) {
            "Do not show this support popup again on this PC?"
        }
        else {
            [string]$cfg.dismiss_prompt
        }

        $dismissResult = [System.Windows.MessageBox]::Show($dismissAsk, $title, "YesNo", "Question")
        if ($dismissResult -eq "Yes") {
            New-Item -Path $StatePath -ItemType File -Force | Out-Null
        }
    }

    exit 0
}
catch {
    # Do not block repair flow if popup fails on headless/locked environments.
    exit 0
}
