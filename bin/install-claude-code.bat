@echo off
setlocal

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
:: Step 1: Install Chocolatey (if not present)
:: -----------------------------------------------------------
where choco >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Chocolatey...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if %errorlevel% neq 0 (
        echo [FAIL] Chocolatey installation failed.
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
    echo Installing Node.js...
    choco install nodejs -y
    call refreshenv
    where node >nul 2>&1
    if %errorlevel% neq 0 (
        echo [FAIL] Node.js installation failed.
        pause
        exit /b 1
    )
    echo [OK] Node.js installed
) else (
    echo [SKIP] Node.js already installed
)
echo.

:: -----------------------------------------------------------
:: Step 3: Install Claude Code
:: -----------------------------------------------------------
echo Installing Claude Code...
call npm install -g @anthropic-ai/claude-code
if %errorlevel% neq 0 (
    echo [FAIL] Claude Code installation failed.
    pause
    exit /b 1
)
echo [OK] Claude Code installed
echo.

:: -----------------------------------------------------------
:: Step 4: Configure Git identity (if not already set)
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
echo   Run "claude" to start Claude Code.
echo ============================================
pause
