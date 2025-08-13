@echo off
REM === Configuration ===
set REMOTE_IP=192.168.1.100
set REMOTE_USER=root
set REMOTE_DIR=/root/project-dir
set LOCAL_DIR=%cd%
set INCLUDE_FILE=include.txt
set EXCLUDE_GENERATED=filelist.txt,sync.bat

:loop
echo Generating file list excluding .gitignore entries...

REM Create a temporary list of files (excluding .gitignore patterns)
git ls-files --cached --others --exclude-standard > filelist.txt

REM If include.txt exists, append those files
if exist "%INCLUDE_FILE%" (
    type "%INCLUDE_FILE%" >> filelist.txt
)

REM Use tar over ssh to send all files at once
tar -cf - -T filelist.txt | ssh %REMOTE_USER%@%REMOTE_IP% "tar -xf - -C %REMOTE_DIR%"

echo Sync complete. Waiting before next sync...
timeout /t 5 /nobreak >nul
goto loop
