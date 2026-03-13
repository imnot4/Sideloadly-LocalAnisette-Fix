# Release vX.Y.Z

## What changed

- 
- 
- 

## Fixed scenarios

- Local Anisette problem
- Local Anisette init err
- `libxml2.dll` load failure in `an` folder
- x86/x64 anisette mismatch
- RUNASADMIN compatibility conflict
- optional Apple TLS certificate trust repair

## Verification

1. Download release zip
2. Verify SHA256 against `SHA256SUMS`
3. Optionally check VirusTotal report
4. Run `Run-Fix.cmd`

## Upgrade notes

- Existing `an` folder is backed up automatically as `an_backup_<timestamp>`.
- If needed, use `Run-Fix-Admin.cmd` for ADI permission issues.

## Known limits

- Corporate endpoint security can block DLL loading regardless of script fixes.
- Microsoft Store iTunes can still be unstable for Local Anisette.
