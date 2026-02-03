@echo off
setlocal EnableDelayedExpansion

:: --- TEST FLAGS (set to 1 to simulate failures) ---
set "TEST_FAIL_NETWORK=0"
set "TEST_FAIL_CLAUDE=0"
set "TEST_FAIL_CHOCO=0"
set "TEST_FAIL_TERMINAL=0"
:: --- END TEST FLAGS ---

:: Track optional install failures
set "OPT_FAILURES="

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
if "!TEST_FAIL_NETWORK!"=="1" (
    echo [ERROR] Cannot reach the internet.
    echo.
    echo Please try again later by re-running the installer from:
    echo     %~dp0install-claude-code.bat
    echo.
    pause
    exit /b 1
)
powershell -NoProfile -Command "try { $null = Invoke-WebRequest -Uri 'https://github.com' -UseBasicParsing -TimeoutSec 10; exit 0 } catch { Write-Host '[ERROR] Cannot reach the internet.' -ForegroundColor Red; Write-Host ''; Write-Host 'Diagnostics:' -ForegroundColor Yellow; $a = Get-NetIPAddress -AddressFamily IPv4 -Type Unicast -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -ne '127.0.0.1' }; if (-not $a) { Write-Host '  - No active network connection detected' -ForegroundColor Yellow } else { Write-Host \"  - Network adapter connected (IP: $($a[0].IPAddress))\" -ForegroundColor Yellow; try { $null = Resolve-DnsName 'claude.ai' -ErrorAction Stop; Write-Host '  - DNS resolution: OK' -ForegroundColor Yellow; Write-Host '  - HTTPS connection failed (may be blocked by firewall or proxy)' -ForegroundColor Yellow } catch { Write-Host '  - DNS resolution failed' -ForegroundColor Yellow } }; exit 1 }"
if %errorlevel% neq 0 (
    echo.
    echo Please try again later by re-running the installer from:
    echo     %~dp0install-claude-code.bat
    echo.
    pause
    exit /b 1
)
echo [OK] Network connectivity confirmed
echo.

:: -----------------------------------------------------------
:: Step 1: Install Claude Code
:: -----------------------------------------------------------
if "!TEST_FAIL_CLAUDE!"=="1" (
    echo [FAIL] Unable to download Claude Code from https://claude.ai
    echo.
    echo Please try again later by re-running the installer from:
    echo     %~dp0install-claude-code.bat
    pause
    exit /b 1
)
where claude >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Claude Code...
    set "CLAUDE_RESULT=1"
    for /L %%i in (1,1,3) do (
        if !CLAUDE_RESULT! neq 0 (
            if %%i gtr 1 echo Retrying ^(attempt %%i of 3^)...
            powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex"
            if !errorlevel! equ 0 (
                set "CLAUDE_RESULT=0"
            ) else (
                if %%i lss 3 (
                    echo [WARN] Attempt %%i failed. Retrying in 5 seconds...
                    timeout /t 5 /nobreak >nul
                )
            )
        )
    )
    if !CLAUDE_RESULT! neq 0 (
        echo [FAIL] Unable to download Claude Code from https://claude.ai
        echo.
        echo Please try again later by re-running the installer from:
        echo     %~dp0install-claude-code.bat
        pause
        exit /b 1
    )
    echo [OK] Claude Code installed
) else (
    echo [SKIP] Claude Code already installed
)
echo.

:: -----------------------------------------------------------
:: Step 2: Install Chocolatey (optional, needed for
::         Windows Terminal)
:: -----------------------------------------------------------
if "!TEST_FAIL_CHOCO!"=="1" (
    echo [WARN] Unable to download Chocolatey from https://community.chocolatey.org
    if defined OPT_FAILURES (set "OPT_FAILURES=!OPT_FAILURES!, Chocolatey") else (set "OPT_FAILURES=Chocolatey")
    goto :skip_choco
)
where choco >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Chocolatey...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if %errorlevel% neq 0 (
        echo [WARN] Unable to download Chocolatey from https://community.chocolatey.org
        if defined OPT_FAILURES (set "OPT_FAILURES=!OPT_FAILURES!, Chocolatey") else (set "OPT_FAILURES=Chocolatey")
        goto :skip_choco
    )
    echo [OK] Chocolatey installed
    call refreshenv
) else (
    echo [SKIP] Chocolatey already installed
)
:skip_choco
echo.

:: -----------------------------------------------------------
:: Step 3: Install Windows Terminal (optional)
:: -----------------------------------------------------------
if "!TEST_FAIL_TERMINAL!"=="1" (
    echo [WARN] Unable to install Windows Terminal.
    if defined OPT_FAILURES (set "OPT_FAILURES=!OPT_FAILURES!, Windows Terminal") else (set "OPT_FAILURES=Windows Terminal")
    goto :skip_terminal
)
where wt >nul 2>&1
if %errorlevel% neq 0 (
    where choco >nul 2>&1
    if %errorlevel% neq 0 (
        echo [SKIP] Windows Terminal requires Chocolatey, which is not available.
        if defined OPT_FAILURES (set "OPT_FAILURES=!OPT_FAILURES!, Windows Terminal") else (set "OPT_FAILURES=Windows Terminal")
        goto :skip_terminal
    )
    call :choco_install_retry microsoft-windows-terminal
    call refreshenv
    where wt >nul 2>&1
    if %errorlevel% neq 0 (
        echo [WARN] Unable to install Windows Terminal.
        if defined OPT_FAILURES (set "OPT_FAILURES=!OPT_FAILURES!, Windows Terminal") else (set "OPT_FAILURES=Windows Terminal")
    ) else (
        echo [OK] Windows Terminal installed
    )
) else (
    echo [SKIP] Windows Terminal already installed
)
:skip_terminal
echo.

:: -----------------------------------------------------------
:: Step 4: Configure Git identity (if not already set)
:: -----------------------------------------------------------
git config --global user.name >nul 2>&1
if %errorlevel% neq 0 (
    echo Git user name is not configured.
    set "GIT_NAME="
    set /p GIT_NAME="Enter your name for Git commits (or press Enter to skip): "
    if defined GIT_NAME (
        git config --global user.name "!GIT_NAME!"
        echo [OK] Git user.name set
    ) else (
        echo [SKIP] Git user.name skipped
    )
) else (
    echo [SKIP] Git user.name already configured
)

git config --global user.email >nul 2>&1
if %errorlevel% neq 0 (
    echo Git email is not configured.
    set "GIT_EMAIL="
    set /p GIT_EMAIL="Enter your email for Git commits (or press Enter to skip): "
    if defined GIT_EMAIL (
        git config --global user.email "!GIT_EMAIL!"
        echo [OK] Git user.email set
    ) else (
        echo [SKIP] Git user.email skipped
    )
) else (
    echo [SKIP] Git user.email already configured
)
echo.

:: -----------------------------------------------------------
:: Summary
:: -----------------------------------------------------------
echo ============================================
echo   Setup complete!
echo.
if defined OPT_FAILURES (
    echo   NOTE: The following optional installs failed:
    echo    !OPT_FAILURES!
    echo   You can re-run this installer later to retry:
    echo     %~dp0install-claude-code.bat
    echo.
)
echo   To start Claude Code:
echo     1. Open your development folder in File Explorer
echo        (e.g. C:\dev\p4\project-name)
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
