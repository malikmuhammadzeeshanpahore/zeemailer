@echo off
setlocal EnableDelayedExpansion
title ZeeMailer Installer

echo.
echo  =============================================
echo     ZeeMailer Installer for Windows
echo  =============================================
echo.

set "APP_DIR=%cd%"
set "TOOLS_DIR=%APP_DIR%\tools"
set "NODE_LOCAL=%TOOLS_DIR%\nodejs"
set "NODE_EXE=%NODE_LOCAL%\node.exe"
set "NPM_CMD=%NODE_LOCAL%\npm.cmd"
set "BIN_DIR=%USERPROFILE%\.local\bin"
set "DESKTOP=%USERPROFILE%\Desktop"

:: ─── Step 1: Check for Node.js ──────────────────────────────────────────────
echo  [1/4] Checking for Node.js...

:: First check if we already have a local portable node (from previous install)
if exist "%NODE_EXE%" (
    echo        Found local portable Node.js.
    goto :npm_install
)

:: Check system-installed node
set "USE_SYSTEM_NODE=0"
where node >nul 2>nul
if %errorlevel% equ 0 (
    for /f "delims=" %%V in ('node -e "process.stdout.write(String(parseInt(process.version.slice(1))))" 2^>nul') do set "NODE_MAJOR=%%V"
    if defined NODE_MAJOR (
        if !NODE_MAJOR! GEQ 18 (
            echo        System Node.js v!NODE_MAJOR!.x found - OK.
            set "NODE_EXE=node"
            set "NPM_CMD=npm"
            set "USE_SYSTEM_NODE=1"
            goto :npm_install
        ) else (
            echo        System Node.js v!NODE_MAJOR!.x is too old. Will use portable version.
        )
    )
)

:: ─── Download portable Node.js ZIP (no install, no restart needed) ────────────
echo        Node.js not found. Downloading portable Node.js v20 LTS...
echo        (This is a one-time download ~30MB. Please wait...)
echo.

if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"
if not exist "%NODE_LOCAL%" mkdir "%NODE_LOCAL%"

set "NODE_VER=v20.18.1"
set "NODE_DIR=node-%NODE_VER%-win-x64"
set "NODE_ZIP=%TEMP%\zeemailer_node.zip"

:: Download the portable zip
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { Invoke-WebRequest -Uri 'https://nodejs.org/dist/%NODE_VER%/%NODE_DIR%.zip' -OutFile '%NODE_ZIP%' -UseBasicParsing; Write-Host 'Download complete.' } catch { Write-Host 'ERROR: ' + $_.Exception.Message; exit 1 }"

if %errorlevel% neq 0 (
    echo.
    echo  ERROR: Failed to download Node.js. Check your internet connection.
    pause
    exit /b 1
)

if not exist "%NODE_ZIP%" (
    echo  ERROR: Download file not found.
    pause
    exit /b 1
)

echo        Extracting Node.js...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { Expand-Archive -Path '%NODE_ZIP%' -DestinationPath '%TEMP%\zeemailer_nodeextract' -Force; Write-Host 'Extracted OK.' } catch { Write-Host 'ERROR: ' + $_.Exception.Message; exit 1 }"

if %errorlevel% neq 0 (
    echo  ERROR: Extraction failed.
    del "%NODE_ZIP%" >nul 2>nul
    pause
    exit /b 1
)

:: Move node files into our tools folder
xcopy /s /e /q /y "%TEMP%\zeemailer_nodeextract\%NODE_DIR%\*" "%NODE_LOCAL%\" >nul

:: Cleanup
rmdir /s /q "%TEMP%\zeemailer_nodeextract" >nul 2>nul
del "%NODE_ZIP%" >nul 2>nul

if not exist "%NODE_EXE%" (
    echo  ERROR: Node.js extraction failed. Missing: %NODE_EXE%
    pause
    exit /b 1
)

echo        Node.js is ready ^(portable, no restart needed^).

:: ─── Step 2: Install npm dependencies ─────────────────────────────────────────
:npm_install
echo.
echo  [2/4] Installing dependencies...

if "%USE_SYSTEM_NODE%"=="1" (
    call npm install --omit=dev
) else (
    :: Use local npm — portable node includes npm in node_modules\npm\bin\npm-cli.js
    "%NODE_EXE%" "%NODE_LOCAL%\node_modules\npm\bin\npm-cli.js" install --omit=dev
)

if %errorlevel% neq 0 (
    echo  ERROR: npm install failed!
    pause
    exit /b 1
)
echo        Dependencies installed.

:: ─── Step 3: Create zeemailer.bat launcher ─────────────────────────────────────
echo.
echo  [3/4] Creating 'zeemailer' command...

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

:: Determine which node to use in the launcher
set "LAUNCHER_NODE=%NODE_EXE%"
if "%USE_SYSTEM_NODE%"=="1" set "LAUNCHER_NODE=node"

(
    echo @echo off
    echo :: ZeeMailer Launcher
    echo :: Restore desktop shortcut if deleted
    echo if not exist "%DESKTOP%\ZeeMailer.lnk" ^(
    echo     powershell -NoProfile -ExecutionPolicy Bypass -Command ^"$s=^(New-Object -ComObject WScript.Shell^).CreateShortcut^('%DESKTOP%\ZeeMailer.lnk'^);$s.TargetPath='%BIN_DIR%\zeemailer.bat';$s.WorkingDirectory='%APP_DIR%';$s.Description='AI-Assisted Email Marketing Tool';$s.IconLocation='%APP_DIR%\assets\logo.png';$s.Save^(^)^"
    echo ^)
    echo cd /d "%APP_DIR%"
    echo "%LAUNCHER_NODE%" server.js
    echo pause
) > "%BIN_DIR%\zeemailer.bat"

:: Add BIN_DIR to User PATH permanently
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$p=[System.Environment]::GetEnvironmentVariable('PATH','User'); if($p -notlike '*%BIN_DIR%*'){[System.Environment]::SetEnvironmentVariable('PATH',$p+';%BIN_DIR%','User')}"

echo        'zeemailer' command created.

:: ─── Step 4: Desktop Shortcut ──────────────────────────────────────────────────
echo.
echo  [4/4] Creating desktop shortcut...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%DESKTOP%\ZeeMailer.lnk');$s.TargetPath='%BIN_DIR%\zeemailer.bat';$s.WorkingDirectory='%APP_DIR%';$s.Description='AI-Assisted Email Marketing Tool';$s.IconLocation='%APP_DIR%\assets\logo.png';$s.Save()"

if exist "%DESKTOP%\ZeeMailer.lnk" (
    echo        Desktop shortcut created.
) else (
    echo        Warning: Could not create shortcut. You can still run zeemailer.bat manually.
)

echo.
echo  =============================================
echo     Installation Complete!
echo.
echo     How to launch ZeeMailer:
echo     * Double-click ZeeMailer on your Desktop
echo     * Or open a NEW terminal and type:
echo       zeemailer
echo  =============================================
echo.
pause
