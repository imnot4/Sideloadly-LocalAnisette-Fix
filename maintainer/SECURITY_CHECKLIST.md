# Security Checklist

Use this checklist before running or sharing the fix.

## 1) Review source code

Open `Fix-Sideloadly-LocalAnisette.ps1` and verify there is no:

- Apple ID/password prompt
- log exfiltration to third-party services
- unrelated destructive file operations

## 2) Review network targets

Expected URLs are:

- `https://sideloadly.io/anis-32.zip`
- `https://sideloadly.io/anis-64.zip`
- official Apple certificate files on `https://www.apple.com/...`

Quick check:

```powershell
Select-String -Path .\Fix-Sideloadly-LocalAnisette.ps1 -Pattern 'https://'
```

## 3) Verify SHA256

Compare local hashes with published `SHA256SUMS`:

```powershell
Get-FileHash .\Fix-Sideloadly-LocalAnisette.ps1 -Algorithm SHA256
```

## 4) Check signature status

```powershell
Get-AuthenticodeSignature .\Fix-Sideloadly-LocalAnisette.ps1
```

## 5) VirusTotal scan

Upload the release zip to VirusTotal and publish the report link.

## 6) Dry-run style execution

Run the script without UI launch first:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Fix-Sideloadly-LocalAnisette.ps1 -NoLaunch
```
