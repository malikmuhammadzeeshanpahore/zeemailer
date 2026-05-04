@echo off
setlocal

echo ===================================
echo  Installing ZeeMailer for Windows... 
echo ===================================

:: Check for Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo Node.js could not be found.
    echo Please install Node.js from https://nodejs.org/ and try again.
    pause
    exit /b 1
)

echo Node.js found.

:: Install Dependencies
echo Installing dependencies...
call npm install

set APP_DIR=%cd%

:: Create a batch script wrapper
echo Creating 'zeemailer' command...
set BIN_DIR=%USERPROFILE%\.local\bin
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

(
echo @echo off
echo set "LINK_FILE=%%USERPROFILE%%\Desktop\ZeeMailer.lnk"
echo if not exist "%%LINK_FILE%%" ^(
echo     echo Restoring Desktop Shortcut...
echo     set "VBS_SCRIPT=%%temp%%\RestoreShortcut.vbs"
echo     echo Set oWS = WScript.CreateObject^("WScript.Shell"^) ^> "%%VBS_SCRIPT%%"
echo     echo sLinkFile = "%%LINK_FILE%%" ^>^> "%%VBS_SCRIPT%%"
echo     echo Set oLink = oWS.CreateShortcut^(sLinkFile^) ^>^> "%%VBS_SCRIPT%%"
echo     echo oLink.TargetPath = "%BIN_DIR%\zeemailer.bat" ^>^> "%%VBS_SCRIPT%%"
echo     echo oLink.WorkingDirectory = "%APP_DIR%" ^>^> "%%VBS_SCRIPT%%"
echo     echo oLink.Description = "AI-Assisted Email Marketing Tool" ^>^> "%%VBS_SCRIPT%%"
echo     echo oLink.IconLocation = "%APP_DIR%\assets\logo.png" ^>^> "%%VBS_SCRIPT%%"
echo     echo oLink.Save ^>^> "%%VBS_SCRIPT%%"
echo     cscript /nologo "%%VBS_SCRIPT%%"
echo     del "%%VBS_SCRIPT%%"
echo ^)
echo cd /d "%APP_DIR%"
echo node server.js
) > "%BIN_DIR%\zeemailer.bat"

:: Add to PATH (User level)
echo Checking PATH...
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%B"

echo %USER_PATH% | findstr /i /c:"%BIN_DIR%" >nul
if %errorlevel% neq 0 (
    echo Adding %BIN_DIR% to User PATH...
    setx PATH "%USER_PATH%;%BIN_DIR%"
    echo Note: You might need to restart your terminal to use 'zeemailer' command.
)

:: Create Desktop Shortcut using PowerShell
echo Creating Desktop Shortcut...
set "VBS_SCRIPT=%temp%\CreateShortcut.vbs"
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%VBS_SCRIPT%"
echo sLinkFile = "%USERPROFILE%\Desktop\ZeeMailer.lnk" >> "%VBS_SCRIPT%"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%VBS_SCRIPT%"
echo oLink.TargetPath = "%BIN_DIR%\zeemailer.bat" >> "%VBS_SCRIPT%"
echo oLink.WorkingDirectory = "%APP_DIR%" >> "%VBS_SCRIPT%"
echo oLink.Description = "AI-Assisted Email Marketing Tool" >> "%VBS_SCRIPT%"
echo oLink.IconLocation = "%APP_DIR%\assets\logo.png" >> "%VBS_SCRIPT%"
echo oLink.Save >> "%VBS_SCRIPT%"

cscript /nologo "%VBS_SCRIPT%"
del "%VBS_SCRIPT%"

echo ===================================
echo  Installation Complete!
echo  You can now double-click 'ZeeMailer' on your Desktop
echo  Or run 'zeemailer' from your terminal.
echo ===================================
pause
