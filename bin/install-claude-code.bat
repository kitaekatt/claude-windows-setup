@echo off
setlocal EnableDelayedExpansion

echo ============================================
echo   Claude Code Installer for Windows
echo ============================================
echo.

:: -----------------------------------------------------------
:: Check 1: Are we running from PowerShell?
:: -----------------------------------------------------------
:: PowerShell sets PSModulePath; plain cmd.exe does not (or it
:: won't contain the PowerShell Modules path).
echo %PSModulePath% | findstr /i "PowerShell" >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script must be run from PowerShell, not cmd.exe.
    echo.
    echo Please open PowerShell as Administrator and run:
    echo     .\install-claude-code.bat
    echo.
    echo To open an elevated PowerShell prompt:
    echo   1. Press Win+X
    echo   2. Select "Windows PowerShell (Admin)" or "Terminal (Admin)"
    echo.
    pause
    exit /b 1
)

:: -----------------------------------------------------------
:: Check 2: Are we running with Administrator privileges?
:: -----------------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires Administrator privileges.
    echo.
    echo Please right-click PowerShell and select "Run as Administrator",
    echo then run this script again.
    echo.
    pause
    exit /b 1
)

echo [OK] Running from elevated PowerShell
echo.

:: -----------------------------------------------------------
:: Check 3: Network connectivity
:: -----------------------------------------------------------
echo Checking network connectivity...
powershell -NoProfile -Command "try { $null = Invoke-WebRequest -Uri 'https://community.chocolatey.org' -UseBasicParsing -TimeoutSec 10; exit 0 } catch { Write-Host '[ERROR] Cannot reach the internet.' -ForegroundColor Red; Write-Host ''; Write-Host 'Diagnostics:' -ForegroundColor Yellow; $a = Get-NetIPAddress -AddressFamily IPv4 -Type Unicast -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -ne '127.0.0.1' }; if (-not $a) { Write-Host '  - No active network connection detected' -ForegroundColor Yellow } else { Write-Host \"  - Network adapter connected (IP: $($a[0].IPAddress))\" -ForegroundColor Yellow; try { $null = Resolve-DnsName 'community.chocolatey.org' -ErrorAction Stop; Write-Host '  - DNS resolution: OK' -ForegroundColor Yellow; Write-Host '  - HTTPS connection failed (may be blocked by firewall or proxy)' -ForegroundColor Yellow } catch { Write-Host '  - DNS resolution failed' -ForegroundColor Yellow } }; exit 1 }"
if %errorlevel% neq 0 (
    echo.
    echo Once your connection is restored, re-run the installer from:
    echo     %~dp0install-claude-code.bat
    echo.
    pause
    exit /b 1
)
echo [OK] Network connectivity confirmed
echo.

:: -----------------------------------------------------------
:: Step 1: Install Chocolatey (if not present)
:: -----------------------------------------------------------
where choco >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Chocolatey...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if %errorlevel% neq 0 (
        echo [FAIL] Chocolatey installation failed.
        echo.
        echo You can re-run this installer from:
        echo     %~dp0install-claude-code.bat
        pause
        exit /b 1
    )
    echo [OK] Chocolatey installed
    :: Refresh PATH so choco is available in this session
    call refreshenv
) else (
    echo [SKIP] Chocolatey already installed
)
echo.

:: -----------------------------------------------------------
:: Step 2: Install Node.js (if not present)
:: -----------------------------------------------------------
where node >nul 2>&1
if %errorlevel% neq 0 (
    call :choco_install_retry nodejs
    call refreshenv
    where node >nul 2>&1
    if %errorlevel% neq 0 (
        echo [FAIL] Node.js installation failed after 3 attempts.
        echo.
        echo You can re-run this installer from:
        echo     %~dp0install-claude-code.bat
        pause
        exit /b 1
    )
    echo [OK] Node.js installed
) else (
    echo [SKIP] Node.js already installed
)
echo.

:: -----------------------------------------------------------
:: Step 3: Install Windows Terminal (if not present)
:: -----------------------------------------------------------
where wt >nul 2>&1
if %errorlevel% neq 0 (
    call :choco_install_retry microsoft-windows-terminal
    call refreshenv
    where wt >nul 2>&1
    if %errorlevel% neq 0 (
        echo [WARN] Windows Terminal installation failed. You can still use PowerShell directly.
    ) else (
        echo [OK] Windows Terminal installed
    )
) else (
    echo [SKIP] Windows Terminal already installed
)
echo.

:: -----------------------------------------------------------
:: Step 4: Install Claude Code
:: -----------------------------------------------------------
set "NPM_RESULT=1"
for /L %%i in (1,1,3) do (
    if !NPM_RESULT! neq 0 (
        echo Installing Claude Code ^(attempt %%i of 3^)...
        call npm install -g @anthropic-ai/claude-code
        if !errorlevel! equ 0 (
            set "NPM_RESULT=0"
        ) else (
            if %%i lss 3 (
                echo [WARN] Attempt %%i failed. Retrying in 5 seconds...
                timeout /t 5 /nobreak >nul
            )
        )
    )
)
if !NPM_RESULT! neq 0 (
    echo [FAIL] Claude Code installation failed after 3 attempts.
    echo.
    echo You can re-run this installer from:
    echo     %~dp0install-claude-code.bat
    pause
    exit /b 1
)
echo [OK] Claude Code installed
echo.

:: -----------------------------------------------------------
:: Step 5: Configure Git identity (if not already set)
:: -----------------------------------------------------------
git config --global user.name >nul 2>&1
if %errorlevel% neq 0 (
    echo Git user name is not configured.
    set /p GIT_NAME="Enter your name for Git commits: "
    git config --global user.name "%GIT_NAME%"
    echo [OK] Git user.name set
) else (
    echo [SKIP] Git user.name already configured
)

git config --global user.email >nul 2>&1
if %errorlevel% neq 0 (
    echo Git email is not configured.
    set /p GIT_EMAIL="Enter your email for Git commits: "
    git config --global user.email "%GIT_EMAIL%"
    echo [OK] Git user.email set
) else (
    echo [SKIP] Git user.email already configured
)
echo.

echo ============================================
echo   Setup complete!
echo.
echo   To start Claude Code:
echo     1. Open your development folder in File Explorer
echo        (e.g. C:\dev\p4)
echo     2. Right-click your work folder (e.g. "main")
echo        and select "Open in Terminal"
echo     3. Type: claude
echo ============================================
pause
goto :eof

:: -----------------------------------------------------------
:: Subroutine: Install a Chocolatey package with retries
:: Usage: call :choco_install_retry <package_name>
:: -----------------------------------------------------------
:choco_install_retry
set "CHOCO_PKG=%~1"
set "CHOCO_RESULT=1"
for /L %%i in (1,1,3) do (
    if !CHOCO_RESULT! neq 0 (
        echo Installing %CHOCO_PKG% ^(attempt %%i of 3^)...
        choco install %CHOCO_PKG% -y
        if !errorlevel! equ 0 (
            set "CHOCO_RESULT=0"
        ) else (
            if %%i lss 3 (
                echo [WARN] Attempt %%i failed. Retrying in 5 seconds...
                timeout /t 5 /nobreak >nul
            )
        )
    )
)
goto :eof
