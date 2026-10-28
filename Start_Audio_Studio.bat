@echo off
setlocal
cd /d "%~dp0"
echo Thai Audio Studio - first launch installs a private Python environment.
echo No administrator account, card or cloud API key is needed.
echo Keep this window open while generating audio.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tool\audio_studio\start.ps1"
if errorlevel 1 (
  echo.
  echo Setup or studio stopped with an error. Read the message above.
  echo Do not enter any credit card or API key.
)
pause
