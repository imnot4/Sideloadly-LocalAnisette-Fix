[CmdletBinding()]
param(
    [string]$SideloadlyDir = (Join-Path $env:LOCALAPPDATA "Sideloadly"),
    [switch]$SkipAnisetteRedownload,
    [switch]$SkipAdiReset,
    [switch]$SkipCertificateFix,
    [switch]$ForceCertificateFix,
    [switch]$NoLaunch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:StartTime = Get-Date
$script:Summary = [ordered]@{
    started_at              = $script:StartTime.ToString("s")
    sideloadly_dir          = $SideloadlyDir
    sideloadly_arch         = $null
    anisette_url            = $null
    anisette_reinstalled    = $false
    gsa_tls_before          = $null
    gsa_tls_after           = $null
    certificates_imported   = @()
    runasadmin_removed      = @()
    user_path_updated       = $false
    adi_files_deleted       = @()
    launched                = $false
    launch_processes        = @()
    warnings                = @()
    errors                  = @()
    log_file                = $null
    report_file             = $null
}

function Write-Step {
    param([string]$Message)
    Write-Host ("[{0}] {1}" -f (Get-Date).ToString("HH:mm:ss"), $Message)
}

function Add-WarningSummary {
    param([string]$Message)
    $script:Summary.warnings += $Message
    Write-Warning $Message
}

function Add-ErrorSummary {
    param([string]$Message)
    $script:Summary.errors += $Message
    Write-Host ("ERROR: {0}" -f $Message) -ForegroundColor Red
}

function Test-IsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-PEArchitecture {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fileStream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $reader = New-Object System.IO.BinaryReader($fileStream)
        [void]$fileStream.Seek(0x3C, [System.IO.SeekOrigin]::Begin)
        $peOffset = $reader.ReadInt32()
        [void]$fileStream.Seek($peOffset + 4, [System.IO.SeekOrigin]::Begin)
        $machine = $reader.ReadUInt16()
        switch ($machine) {
            0x14c { return "x86" }
            0x8664 { return "x64" }
            default { return ("unknown-0x{0:X}" -f $machine) }
        }
    }
    finally {
        $fileStream.Dispose()
    }
}

function Remove-RunAsAdminCompatibility {
    param([Parameter(Mandatory = $true)][string]$ExePath)

    $removed = @()
    $layerKeys = @(
        "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers",
        "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
    )

    foreach ($key in $layerKeys) {
        try {
            if (-not (Test-Path $key)) {
                continue
            }

            $props = Get-ItemProperty -Path $key -ErrorAction Stop
            $value = $props.PSObject.Properties[$ExePath]
            if ($null -ne $value -and $value.Value -match "RUNASADMIN") {
                Remove-ItemProperty -Path $key -Name $ExePath -ErrorAction Stop
                $removed += ("{0} => {1}" -f $key, $ExePath)
            }
        }
        catch {
            Add-WarningSummary ("Could not inspect/update compatibility key '{0}': {1}" -f $key, $_.Exception.Message)
        }
    }

    return $removed
}

function Download-File {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$OutFile
    )

    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
    }
    catch {
        Add-WarningSummary ("Invoke-WebRequest failed for '{0}', trying BITS. Reason: {1}" -f $Url, $_.Exception.Message)
        Start-BitsTransfer -Source $Url -Destination $OutFile -ErrorAction Stop
    }
}

function Ensure-UserPathContains {
    param([Parameter(Mandatory = $true)][string]$DirToAdd)

    $currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ([string]::IsNullOrWhiteSpace($currentUserPath)) {
        [Environment]::SetEnvironmentVariable("Path", $DirToAdd, "User")
        return $true
    }

    $parts = $currentUserPath.Split(";") | Where-Object { $_ -ne "" }
    foreach ($part in $parts) {
        if ($part.Trim().TrimEnd("\") -ieq $DirToAdd.Trim().TrimEnd("\")) {
            return $false
        }
    }

    $newPath = "{0};{1}" -f $DirToAdd, $currentUserPath
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    return $true
}

function Repair-AnisetteFolder {
    param(
        [Parameter(Mandatory = $true)][string]$AnFolder,
        [Parameter(Mandatory = $true)][string]$Arch,
        [Parameter(Mandatory = $true)][string]$RunDir
    )

    $anisetteUrl = if ($Arch -eq "x64") { "https://sideloadly.io/anis-64.zip" } else { "https://sideloadly.io/anis-32.zip" }
    $script:Summary.anisette_url = $anisetteUrl
    Write-Step ("Downloading official anisette package: {0}" -f $anisetteUrl)

    $zipFile = Join-Path $RunDir ("anis-{0}.zip" -f $Arch)
    $extractDir = Join-Path $RunDir ("anis-{0}-extract" -f $Arch)
    $newAnFolder = Join-Path $RunDir "an_new"
    Download-File -Url $anisetteUrl -OutFile $zipFile

    if ((Get-Item $zipFile).Length -lt 2MB) {
        throw "Downloaded anisette archive is too small. Aborting to avoid replacing with a bad file."
    }

    if (Test-Path $extractDir) {
        Remove-Item -Path $extractDir -Recurse -Force
    }
    Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force

    $sourceRoot = if (Test-Path (Join-Path $extractDir "an")) { (Join-Path $extractDir "an") } else { $extractDir }

    foreach ($requiredFile in @("libxml2.dll", "CoreFP.dll", "CoreADI.dll", "iTunesCore.dll")) {
        if (-not (Test-Path (Join-Path $sourceRoot $requiredFile))) {
            throw ("The downloaded package does not contain expected file: {0}" -f $requiredFile)
        }
    }

    if (Test-Path $newAnFolder) {
        Remove-Item -Path $newAnFolder -Recurse -Force
    }
    New-Item -Path $newAnFolder -ItemType Directory -Force | Out-Null
    Copy-Item -Path (Join-Path $sourceRoot "*") -Destination $newAnFolder -Recurse -Force

    $backupFolder = "{0}_backup_{1}" -f $AnFolder, (Get-Date -Format "yyyyMMdd-HHmmss")
    if (Test-Path $AnFolder) {
        Move-Item -Path $AnFolder -Destination $backupFolder -Force
    }

    Move-Item -Path $newAnFolder -Destination $AnFolder -Force
    Get-ChildItem -Path $AnFolder -File -Recurse | ForEach-Object {
        try {
            Unblock-File -Path $_.FullName -ErrorAction Stop
        }
        catch {
            # Ignore unblock issues; ADS stream may not exist.
        }
    }
    $script:Summary.anisette_reinstalled = $true
}

function Test-GsaTls {
    param([string]$Url = "https://gsa.apple.com")

    try {
        $resp = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 30 -MaximumRedirection 3 -ErrorAction Stop
        return [ordered]@{
            ok     = $true
            status = [int]$resp.StatusCode
            detail = "reachable"
        }
    }
    catch {
        try {
            $resp = $_.Exception.Response
            if ($null -ne $resp) {
                $statusCode = [int]$resp.StatusCode
                if ($statusCode -in @(401, 403, 404)) {
                    return [ordered]@{
                        ok     = $true
                        status = $statusCode
                        detail = "reachable (non-200 is expected for this endpoint)"
                    }
                }
            }
        }
        catch {
            # Ignore and fallback to generic error message below.
        }

        return [ordered]@{
            ok     = $false
            status = $null
            detail = $_.Exception.Message
        }
    }
}

function Install-CertificateToCurrentUserStore {
    param(
        [Parameter(Mandatory = $true)][string]$CertFile,
        [Parameter(Mandatory = $true)][string]$StoreName
    )

    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertFile)
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($StoreName, "CurrentUser")
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    try {
        $existing = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
        if (@($existing).Count -gt 0) {
            return [ordered]@{
                thumbprint = $cert.Thumbprint
                subject    = $cert.Subject
                store      = $StoreName
                status     = "already_present"
            }
        }

        $store.Add($cert)
        return [ordered]@{
            thumbprint = $cert.Thumbprint
            subject    = $cert.Subject
            store      = $StoreName
            status     = "installed"
        }
    }
    finally {
        $store.Close()
    }
}

function Ensure-AppleCertificates {
    param([Parameter(Mandatory = $true)][string]$RunDir)

    $certDir = Join-Path $RunDir "certs"
    New-Item -Path $certDir -ItemType Directory -Force | Out-Null

    # Official Apple PKI certificates (roots + intermediates commonly used for Apple services).
    $certSpecs = @(
        @{ File = "AppleIncRootCertificate.cer"; Url = "https://www.apple.com/appleca/AppleIncRootCertificate.cer"; Store = "Root" },
        @{ File = "AppleRootCA-G2.cer"; Url = "https://www.apple.com/certificateauthority/AppleRootCA-G2.cer"; Store = "Root" },
        @{ File = "AppleRootCA-G3.cer"; Url = "https://www.apple.com/certificateauthority/AppleRootCA-G3.cer"; Store = "Root" },
        @{ File = "AppleISTCA2G1.cer"; Url = "https://www.apple.com/certificateauthority/AppleISTCA2G1.cer"; Store = "CA" },
        @{ File = "AppleISTCA8G1.cer"; Url = "https://www.apple.com/certificateauthority/AppleISTCA8G1.cer"; Store = "CA" },
        @{ File = "AppleAAICA.cer"; Url = "https://www.apple.com/certificateauthority/AppleAAICA.cer"; Store = "CA" }
    )

    foreach ($spec in $certSpecs) {
        $localFile = Join-Path $certDir $spec.File
        try {
            Download-File -Url $spec.Url -OutFile $localFile
            $result = Install-CertificateToCurrentUserStore -CertFile $localFile -StoreName $spec.Store
            $result["source_url"] = $spec.Url
            $script:Summary.certificates_imported += $result
        }
        catch {
            Add-WarningSummary ("Could not install certificate '{0}' from '{1}': {2}" -f $spec.File, $spec.Url, $_.Exception.Message)
        }
    }
}

function Reset-AdiFiles {
    param([Parameter(Mandatory = $true)][string]$AdiDir)

    if (-not (Test-Path $AdiDir)) {
        New-Item -Path $AdiDir -ItemType Directory -Force | Out-Null
    }

    foreach ($pattern in @("adi.pb", "adi-*.pb")) {
        Get-ChildItem -Path $AdiDir -Filter $pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force -ErrorAction Stop
                $script:Summary.adi_files_deleted += $_.Name
            }
            catch {
                Add-WarningSummary ("Failed to delete ADI file '{0}': {1}" -f $_.FullName, $_.Exception.Message)
            }
        }
    }
}

function Get-ItunesStatus {
    $desktopItunes = @(
        (Join-Path ${env:ProgramFiles} "iTunes\iTunes.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "iTunes\iTunes.exe")
    ) | Where-Object { Test-Path $_ }

    $storeItunes = @()
    try {
        $storeItunes = Get-AppxPackage -Name "*iTunes*" -ErrorAction SilentlyContinue
    }
    catch {
        # Appx cmdlets may be unavailable on older PowerShell images.
    }

    $storeCount = @($storeItunes).Count
    $desktopCount = @($desktopItunes).Count

    if ($storeCount -gt 0 -and $desktopCount -eq 0) {
        Add-WarningSummary "Only Microsoft Store iTunes detected. Local Anisette is more stable with web iTunes/iCloud installers."
    }
    elseif ($desktopCount -eq 0) {
        Add-WarningSummary "Desktop iTunes not detected. Install web iTunes from Apple if Local Anisette still fails."
    }
}

function Launch-Sideloadly {
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [switch]$SkipLaunch
    )

    if ($SkipLaunch) {
        Write-Step "NoLaunch switch was set, skipping start."
        return
    }

    $daemonPath = Join-Path $Dir "sideloadlydaemon.exe"
    $uiPath = Join-Path $Dir "sideloadly.exe"

    Push-Location $Dir
    try {
        if (Test-Path $daemonPath) {
            $daemon = Start-Process -FilePath $daemonPath -WorkingDirectory $Dir -PassThru
            Start-Sleep -Seconds 1
            $script:Summary.launch_processes += ("daemon:{0}" -f $daemon.Id)
        }
        $ui = Start-Process -FilePath $uiPath -WorkingDirectory $Dir -PassThru
        Start-Sleep -Milliseconds 900
        $script:Summary.launch_processes += ("ui:{0}" -f $ui.Id)
        $script:Summary.launched = $true

        try {
            $wsh = New-Object -ComObject WScript.Shell
            [void]$wsh.AppActivate("Sideloadly")
        }
        catch {
            # Foreground focus is best-effort only.
        }
    }
    finally {
        Pop-Location
    }
}

$projectDir = Split-Path -Path $PSCommandPath -Parent
$runRoot = Join-Path $projectDir "runs"
New-Item -Path $runRoot -ItemType Directory -Force | Out-Null
$runDir = Join-Path $runRoot ("run-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -Path $runDir -ItemType Directory -Force | Out-Null
$logFile = Join-Path $runDir "fix.log"
$reportFile = Join-Path $runDir "report.json"
$script:Summary.log_file = $logFile
$script:Summary.report_file = $reportFile

Start-Transcript -Path $logFile -Force | Out-Null

try {
    Write-Step "Starting Local Anisette repair."
    if (-not (Test-Path $SideloadlyDir)) {
        throw ("Sideloadly folder not found: {0}" -f $SideloadlyDir)
    }

    $sideloadlyExe = Join-Path $SideloadlyDir "sideloadly.exe"
    $daemonExe = Join-Path $SideloadlyDir "sideloadlydaemon.exe"
    if (-not (Test-Path $sideloadlyExe)) {
        throw ("sideloadly.exe not found in: {0}" -f $SideloadlyDir)
    }

    Write-Step "Stopping running Sideloadly processes."
    Get-Process sideloadly, sideloadlydaemon -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 500

    Write-Step "Removing RUNASADMIN compatibility entries if present."
    $removedCompat = @()
    $removedCompat += Remove-RunAsAdminCompatibility -ExePath $sideloadlyExe
    if (Test-Path $daemonExe) {
        $removedCompat += Remove-RunAsAdminCompatibility -ExePath $daemonExe
    }
    $script:Summary.runasadmin_removed = $removedCompat

    $arch = Get-PEArchitecture -Path $sideloadlyExe
    $script:Summary.sideloadly_arch = $arch
    Write-Step ("Detected sideloadly.exe architecture: {0}" -f $arch)

    if ($arch -notin @("x86", "x64")) {
        Add-WarningSummary ("Unknown binary architecture '{0}'. Defaulting anisette package to x64." -f $arch)
        $arch = "x64"
    }

    Write-Step "Checking TLS trust to gsa.apple.com."
    $tlsBefore = Test-GsaTls
    $script:Summary.gsa_tls_before = $tlsBefore
    if ($ForceCertificateFix) {
        Write-Step "ForceCertificateFix is set; installing Apple certificates."
        if (-not $SkipCertificateFix) {
            Ensure-AppleCertificates -RunDir $runDir
            $tlsAfter = Test-GsaTls
            $script:Summary.gsa_tls_after = $tlsAfter
        }
        else {
            Add-WarningSummary "ForceCertificateFix requested but SkipCertificateFix is also set. Certificate repair skipped."
            $script:Summary.gsa_tls_after = $tlsBefore
        }
    }
    elseif (-not $tlsBefore.ok) {
        Add-WarningSummary ("Initial TLS check failed for gsa.apple.com: {0}" -f $tlsBefore.detail)
        if (-not $SkipCertificateFix) {
            Write-Step "Installing Apple certificates to CurrentUser stores (Root/CA)."
            Ensure-AppleCertificates -RunDir $runDir
            $tlsAfter = Test-GsaTls
            $script:Summary.gsa_tls_after = $tlsAfter
            if (-not $tlsAfter.ok) {
                Add-WarningSummary ("TLS check still failing after certificate install: {0}" -f $tlsAfter.detail)
            }
        }
        else {
            Add-WarningSummary "SkipCertificateFix was set; certificate repair was skipped."
            $script:Summary.gsa_tls_after = $tlsBefore
        }
    }
    else {
        $script:Summary.gsa_tls_after = $tlsBefore
    }

    $anFolder = Join-Path $SideloadlyDir "an"
    if (-not $SkipAnisetteRedownload) {
        Repair-AnisetteFolder -AnFolder $anFolder -Arch $arch -RunDir $runDir
    }
    else {
        Write-Step "SkipAnisetteRedownload is set; keeping current an folder."
    }

    Write-Step "Ensuring PATH contains Sideloadly anisette folder."
    $env:Path = "{0};{1}" -f $anFolder, $env:Path
    $pathChanged = Ensure-UserPathContains -DirToAdd $anFolder
    $script:Summary.user_path_updated = $pathChanged

    if (-not $SkipAdiReset) {
        $adiDir = Join-Path $env:ProgramData "Apple Computer\iTunes\adi"
        Write-Step ("Resetting stale ADI blobs in: {0}" -f $adiDir)
        Reset-AdiFiles -AdiDir $adiDir
    }
    else {
        Write-Step "SkipAdiReset is set; leaving ADI files untouched."
    }

    Get-ItunesStatus

    $isAdmin = Test-IsAdmin
    if (-not $isAdmin) {
        Add-WarningSummary "Script is running without admin rights. If ADI permission errors persist, run as Administrator one time."
    }

    Write-Step "Launching Sideloadly with fixed environment."
    Launch-Sideloadly -Dir $SideloadlyDir -SkipLaunch:$NoLaunch

    Write-Step "Repair finished."
}
catch {
    $message = $_.Exception.Message
    Add-ErrorSummary $message
}
finally {
    $script:Summary.ended_at = (Get-Date).ToString("s")
    $script:Summary.duration_seconds = [int]((Get-Date) - $script:StartTime).TotalSeconds
    $script:Summary | ConvertTo-Json -Depth 6 | Set-Content -Path $reportFile -Encoding UTF8
    Stop-Transcript | Out-Null
}

if ($script:Summary.errors.Count -gt 0) {
    Write-Host ""
    Write-Host "FAILED. See report:"
    Write-Host $reportFile
    exit 1
}

Write-Host ""
Write-Host "SUCCESS. See report:"
Write-Host $reportFile
exit 0
