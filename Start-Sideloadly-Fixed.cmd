@echo off
setlocal EnableExtensions

set "SL=%LOCALAPPDATA%\Sideloadly"

if not exist "%SL%\sideloadly.exe" (
  echo Sideloadly not found: %SL%
  pause
  exit /b 1
)

reg delete "HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%SL%\sideloadly.exe" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%SL%\sideloadlydaemon.exe" /f >nul 2>&1

taskkill /F /IM sideloadly.exe /IM sideloadlydaemon.exe >nul 2>&1

set "PATH=%SL%\an;%PATH%"
pushd "%SL%" >nul
if exist "%SL%\sideloadlydaemon.exe" (
  start "" "%SL%\sideloadlydaemon.exe"
  timeout /t 1 /nobreak >nul
)
start "" "%SL%\sideloadly.exe"
popd >nul

exit /b 0
