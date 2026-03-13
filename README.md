# Sideloadly Local Anisette Fix (Windows)

Fixes common Sideloadly errors like:

- `Local Anisette problem`
- `Local Anisette init err`
- `Failed to load ...\an\libxml2.dll`

## Quick Start

1. Extract the zip to any folder.
2. Double-click `Start-Here.cmd`.
3. Wait for `Repair completed`.
4. Open Sideloadly normally.

## Which file should I run?

- `Start-Here.cmd`:
  Use this in almost all cases. It runs the standard repair flow and can offer Admin mode automatically if needed.
- `Run-Fix-Admin.cmd`:
  Use only if standard mode fails with permission-related errors (for example `Access is denied`, ADI write errors).
- `Start-Sideloadly-Fixed.cmd`:
  Optional launcher. Use it only if Sideloadly opens unreliably after a successful repair.

## What the fix changes

1. Stops stale Sideloadly processes.
2. Removes conflicting `RUNASADMIN` compatibility flags.
3. Detects x86/x64 and aligns anisette package with installed Sideloadly.
4. Repairs `%LOCALAPPDATA%\Sideloadly\an` and updates `PATH` if needed.
5. Resets stale ADI blobs when required.
6. Checks TLS access to `gsa.apple.com`; repairs Apple cert trust if needed.
7. Saves logs in `runs\run-<timestamp>\`.

## Safety

- No Apple ID/password collection.
- No external log upload.
- Network is used only for official Sideloadly/Apple downloads required for the fix.

## Notes

- No desktop shortcut is created automatically.
- After successful repair, users can launch Sideloadly normally.
- If the issue returns, run `Start-Here.cmd` again.

## Support

After a successful repair, the launcher can show an optional support popup.
Direct link: `https://boosty.to/not4/donate`
I am saving for a new PC to replace my old one. Not required, but it helps a lot <3
