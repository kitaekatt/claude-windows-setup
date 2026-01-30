@echo off
echo ============================================
echo   GitHub CLI Installer
echo ============================================
echo.

where choco >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Chocolatey is not installed.
    echo.
    echo Please run bin\install-claude-code.bat first, which will install
    echo Chocolatey as part of the setup process.
    echo.
    pause
    exit /b 1
)

echo Installing GitHub CLI via Chocolatey...
choco install gh -y
if %errorlevel% neq 0 (
    echo [FAIL] GitHub CLI installation failed.
    pause
    exit /b 1
)
echo.
echo [OK] GitHub CLI installed
echo.
echo Next step: Run "gh auth login" to authenticate.
pause
