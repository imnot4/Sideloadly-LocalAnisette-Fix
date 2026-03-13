@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
set "PAUSE_ON_EXIT=1"
set "SHOW_SUPPORT=1"
set "FIX_ARGS="

for %%A in (%*) do (
  if /I "%%~A"=="--no-pause" set "PAUSE_ON_EXIT=0"
  if /I "%%~A"=="--skip-support-prompt" set "SHOW_SUPPORT=0"
  if /I "%%~A"=="--no-launch" set "FIX_ARGS=!FIX_ARGS! -NoLaunch"
  if /I "%%~A"=="--skip-anisette-redownload" set "FIX_ARGS=!FIX_ARGS! -SkipAnisetteRedownload"
  if /I "%%~A"=="--skip-adi-reset" set "FIX_ARGS=!FIX_ARGS! -SkipAdiReset"
  if /I "%%~A"=="--skip-certificate-fix" set "FIX_ARGS=!FIX_ARGS! -SkipCertificateFix"
  if /I "%%~A"=="--force-certificate-fix" set "FIX_ARGS=!FIX_ARGS! -ForceCertificateFix"
)

echo Running Local Anisette repair (standard mode)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Fix-Sideloadly-LocalAnisette.ps1" !FIX_ARGS!
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
  echo Repair completed.
) else (
  echo Standard mode failed with exit code %EXIT_CODE%.
  choice /C YN /N /M "Try Administrator mode now? [Y/N]: "
  if errorlevel 2 goto after_admin_try
  call "%SCRIPT_DIR%Run-Fix-Admin.cmd" --skip-support-prompt --no-pause %*
  set "EXIT_CODE=%ERRORLEVEL%"
  echo.
  if "%EXIT_CODE%"=="0" (
    echo Repair completed in Administrator mode.
  ) else (
    echo Administrator mode failed with exit code %EXIT_CODE%.
  )
)

:after_admin_try
if "%EXIT_CODE%"=="0" if "%SHOW_SUPPORT%"=="1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Show-SupportPrompt.ps1" -ConfigPath "%SCRIPT_DIR%support-config.json" -StatePath "%SCRIPT_DIR%.support-dismissed"
)

if "%PAUSE_ON_EXIT%"=="1" (
  echo Press any key to close...
  pause >nul
)
exit /b %EXIT_CODE%
