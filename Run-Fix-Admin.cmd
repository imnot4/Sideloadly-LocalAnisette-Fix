@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
set "PAUSE_ON_EXIT=1"
set "SHOW_SUPPORT=1"
set "IS_ELEVATED=0"
set "FIX_ARGS="

for %%A in (%*) do (
  if /I "%%~A"=="--elevated" set "IS_ELEVATED=1"
  if /I "%%~A"=="--no-pause" set "PAUSE_ON_EXIT=0"
  if /I "%%~A"=="--skip-support-prompt" set "SHOW_SUPPORT=0"
  if /I "%%~A"=="--no-launch" set "FIX_ARGS=!FIX_ARGS! -NoLaunch"
  if /I "%%~A"=="--skip-anisette-redownload" set "FIX_ARGS=!FIX_ARGS! -SkipAnisetteRedownload"
  if /I "%%~A"=="--skip-adi-reset" set "FIX_ARGS=!FIX_ARGS! -SkipAdiReset"
  if /I "%%~A"=="--skip-certificate-fix" set "FIX_ARGS=!FIX_ARGS! -SkipCertificateFix"
  if /I "%%~A"=="--force-certificate-fix" set "FIX_ARGS=!FIX_ARGS! -ForceCertificateFix"
)

if "%IS_ELEVATED%"=="1" goto elevated

echo Requesting administrator rights...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$argsList=@('--elevated'); if('%PAUSE_ON_EXIT%' -eq '0'){ $argsList += '--no-pause' }; if('%SHOW_SUPPORT%' -eq '0'){ $argsList += '--skip-support-prompt' }; foreach($a in @('--no-launch','--skip-anisette-redownload','--skip-adi-reset','--skip-certificate-fix','--force-certificate-fix')){ if(' %* ' -match ('(?i)\s' + [regex]::Escape($a) + '\s')){ $argsList += $a } }; Start-Process -FilePath '%~f0' -ArgumentList $argsList -Verb RunAs"
if errorlevel 1 (
  echo Elevation was cancelled.
  if "%PAUSE_ON_EXIT%"=="1" pause
)
exit /b

:elevated
echo Running Local Anisette repair as Administrator...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Fix-Sideloadly-LocalAnisette.ps1" !FIX_ARGS!
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
  echo Done.
  if "%SHOW_SUPPORT%"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Show-SupportPrompt.ps1" -ConfigPath "%SCRIPT_DIR%support-config.json" -StatePath "%SCRIPT_DIR%.support-dismissed"
  )
) else (
  echo Failed with exit code %EXIT_CODE%.
)
if "%PAUSE_ON_EXIT%"=="1" (
  echo Press any key to close...
  pause >nul
)
exit /b %EXIT_CODE%
