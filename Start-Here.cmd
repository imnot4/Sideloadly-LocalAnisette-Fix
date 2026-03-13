@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

echo Starting Sideloadly Local Anisette Fix...
call "%SCRIPT_DIR%Run-Fix.cmd"
exit /b %ERRORLEVEL%
