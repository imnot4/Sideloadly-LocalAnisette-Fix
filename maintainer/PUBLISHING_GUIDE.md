# Publishing Guide

## Recommended stack

1. Primary: GitHub repository + GitHub Releases
2. Mirror: GitLab or Codeberg
3. Community posts: Reddit/Telegram/forums linking back to source repo only

## Why this works

- Public source and commit history build trust.
- Reproducible releases with SHA256 are easy to verify.
- Faster issue triage via issues/discussions.

## Release package contents

For each release publish:

- release zip
- `SHA256SUMS`
- `SIGNATURES`
- short changelog

## Release flow

1. Update version.
2. Build:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\maintainer\Build-Release.ps1 -Version v1.0.0
```

3. Upload artifacts from `dist` to GitHub Release.
4. Add a verification section with hash check commands.

## Recommended trust statement

> Open-source fix.  
> Verify SHA256 before running.  
> No Apple ID/password collection.  
> No third-party log upload.  
> Network requests are limited to official Sideloadly/Apple URLs.

## What to avoid

- binary-only releases without source
- hidden download mirrors
- bundling third-party DLLs without source/reference
