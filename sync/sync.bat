@echo off
REM === Configuration ===
set REMOTE_IP=192.168.1.100
set REMOTE_USER=root
set REMOTE_DIR=/root/project-dir
set LOCAL_DIR=%cd%
set INCLUDE_FILE=include.txt
set EXCLUDE_GENERATED=filelist.txt,sync.bat,.last_sync_state,include.txt

REM Initialize last sync state
set LAST_SYNC_FILE=.last_sync_state
if not exist "%LAST_SYNC_FILE%" echo. > "%LAST_SYNC_FILE%"

:loop
echo Checking for uncommitted changes...

REM Check if there are any uncommitted changes
git status --porcelain > temp_status.txt
for /f %%i in ("temp_status.txt") do set SIZE=%%~zi
del temp_status.txt

if "%SIZE%"=="0" (
    echo No uncommitted changes detected. Waiting...
    ping 127.0.0.1 -n 6 > nul
    goto loop
)

echo Uncommitted changes detected. Starting sync...

REM Create a temporary list of files (excluding .gitignore patterns)
git ls-files --cached --others --exclude-standard > temp_filelist.txt

REM Add files in INCLUDE_FILE (like .env files that might be gitignored)
if exist "%INCLUDE_FILE%" (
    type "%INCLUDE_FILE%" >> temp_filelist.txt
)

REM Filter out EXCLUDE_GENERATED files
findstr /v /i "%EXCLUDE_GENERATED:,= %" temp_filelist.txt > filelist.txt 2>nul || copy temp_filelist.txt filelist.txt >nul
del temp_filelist.txt

REM Use tar over ssh to send all files at once
tar -cf - -T filelist.txt | ssh %REMOTE_USER%@%REMOTE_IP% "tar -xf - -C %REMOTE_DIR%"

echo Sync complete. Waiting for next changes...
ping 127.0.0.1 -n 6 > nul
goto loop
