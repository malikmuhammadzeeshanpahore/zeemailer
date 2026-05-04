@echo off
setlocal EnableDelayedExpansion
title ZeeMailer Installer

echo ===================================
echo   ZeeMailer Installer - Windows   
echo ===================================
echo.

set "APP_DIR=%cd%"
set "BIN_DIR=%USERPROFILE%\.local\bin"
set "DESKTOP=%USERPROFILE%\Desktop"
set "NODE_MIN=18"

:: ─── Step 1: Check / Install Node.js ────────────────────────────────────────
echo [1/4] Checking Node.js...

where node >nul 2>nul
if %errorlevel% neq 0 (
    goto :install_node
)

:: Check version
for /f "tokens=1 delims=." %%V in ('node -e "process.stdout.write(process.version.slice(1))" 2^>nul') do set "NODE_MAJOR=%%V"
if defined NODE_MAJOR (
    if !NODE_MAJOR! GEQ %NODE_MIN% (
        echo    Node.js v!NODE_MAJOR!.x found - OK
        goto :npm_install
    ) else (
        echo    Node.js v!NODE_MAJOR!.x is too old ^(min: v%NODE_MIN%^). Updating...
        goto :install_node
    )
)

:install_node
echo    Node.js not found. Downloading Node.js LTS installer...

:: Use PowerShell to download Node.js LTS
set "NODE_INSTALLER=%TEMP%\node_installer.msi"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$url = (Invoke-RestMethod 'https://nodejs.org/dist/index.json' | Where-Object { $_.lts } | Select-Object -First 1).files | ForEach-Object { $null } | Out-Null; $ver = (Invoke-RestMethod 'https://nodejs.org/dist/index.json' | Where-Object { $_.lts } | Select-Object -First 1).version; $url = \"https://nodejs.org/dist/$ver/node-$ver-x64.msi\"; Write-Host \"Downloading: $url\"; Invoke-WebRequest -Uri $url -OutFile '%NODE_INSTALLER%' -UseBasicParsing"

if not exist "%NODE_INSTALLER%" (
    echo    Download failed. Trying fallback URL...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.14.0/node-v20.14.0-x64.msi' -OutFile '%NODE_INSTALLER%' -UseBasicParsing"
)

if not exist "%NODE_INSTALLER%" (
    echo.
    echo    ERROR: Could not download Node.js automatically.
    echo    Please install manually from: https://nodejs.org/en/download/
    pause
    exit /b 1
)

echo    Installing Node.js silently (this may take a minute)...
msiexec /i "%NODE_INSTALLER%" /quiet /norestart ADDLOCAL=ALL
del "%NODE_INSTALLER%" >nul 2>nul

:: Refresh PATH for current session
for /f "tokens=*" %%P in ('powershell -NoProfile -Command "[System.Environment]::GetEnvironmentVariable(\"PATH\",\"Machine\") + \";\" + [System.Environment]::GetEnvironmentVariable(\"PATH\",\"User\")"') do set "PATH=%%P"

where node >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo    Node.js installation may need a restart to take effect.
    echo    Please restart your computer and run install.bat again.
    pause
    exit /b 1
)
echo    Node.js installed successfully!

:npm_install
echo.
echo [2/4] Installing dependencies...
call npm install --omit=dev
if %errorlevel% neq 0 (
    echo    npm install failed!
    pause
    exit /b 1
)
echo    Dependencies installed.

:: ─── Step 3: Create zeemailer.bat launcher ───────────────────────────────────
echo.
echo [3/4] Creating 'zeemailer' command...

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

(
    echo @echo off
    echo :: Restore desktop shortcut if missing
    echo if not exist "%DESKTOP%\ZeeMailer.lnk" ^(
    echo     powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%DESKTOP%\ZeeMailer.lnk');$s.TargetPath='%BIN_DIR%\zeemailer.bat';$s.WorkingDirectory='%APP_DIR%';$s.Description='AI-Assisted Email Marketing Tool';$s.IconLocation='%APP_DIR%\assets\logo.png';$s.Save()"
    echo ^)
    echo cd /d "%APP_DIR%"
    echo node server.js
    echo pause
) > "%BIN_DIR%\zeemailer.bat"

:: Add BIN_DIR to user PATH if not present
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$p=[System.Environment]::GetEnvironmentVariable('PATH','User'); if($p -notlike '*%BIN_DIR%*'){[System.Environment]::SetEnvironmentVariable('PATH',$p+';%BIN_DIR%','User'); Write-Host '   Added to PATH.'} else { Write-Host '   Already in PATH.' }"

:: ─── Step 4: Create Desktop Shortcut ─────────────────────────────────────────
echo.
echo [4/4] Creating desktop shortcut...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%DESKTOP%\ZeeMailer.lnk');$s.TargetPath='%BIN_DIR%\zeemailer.bat';$s.WorkingDirectory='%APP_DIR%';$s.Description='AI-Assisted Email Marketing Tool';$s.IconLocation='%APP_DIR%\assets\logo.png';$s.Save()"

if exist "%DESKTOP%\ZeeMailer.lnk" (
    echo    Desktop shortcut created.
) else (
    echo    Warning: Could not create desktop shortcut.
)

echo.
echo ===================================
echo   Installation Complete!
echo.
echo   Launch options:
echo   * Double-click 'ZeeMailer'
echo     on your Desktop
echo   * Or open a NEW terminal and
echo     type: zeemailer
echo ===================================
echo.
pause
