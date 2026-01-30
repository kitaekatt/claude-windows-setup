@echo off
echo Configuring Git for cross-platform compatibility...
echo.

git config --global core.autocrlf input
echo [OK] Line endings: convert CRLF to LF on commit

git config --global core.longpaths true
echo [OK] Long file paths enabled in Git

git config --global core.ignorecase false
echo [OK] Case sensitivity tracking enabled

git config --global core.filemode false
echo [OK] File permission tracking disabled

git config --global core.symlinks true
echo [OK] Symlink support enabled

echo.
echo --- The following requires Administrator privileges ---
echo Enabling long paths at the OS level...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f
if %errorlevel% neq 0 (
    echo [SKIP] OS long paths - re-run this script as Administrator to apply
) else (
    echo [OK] OS long paths enabled
)

echo Enabling Developer Mode...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f
if %errorlevel% neq 0 (
    echo [SKIP] Developer Mode - re-run this script as Administrator to apply
) else (
    echo [OK] Developer Mode enabled
)

echo.
echo Done.
pause
