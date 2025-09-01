@echo off
setlocal
set "BASEDIR=%~dp0"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Starting with admin rights...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Starting PowerShell script with admin rights...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%./Ethernet-WiFi-Switch.ps1"

if errorlevel 1 (
    echo Error occurred! Press any key to exit....
    pause > nul
) else (
    echo.
    echo Done! Press any key to exit...
    pause > nul
)
