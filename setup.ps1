# Claude Windows Setup - Bootstrap Script
# Usage: irm https://raw.githubusercontent.com/kitaekatt/claude-windows-setup/main/setup.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Claude Code - Windows Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check for Administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires Administrator privileges." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please open PowerShell as Administrator (Win+X > 'Terminal (Admin)') and try again."
    Write-Host ""
    return
}

# Prompt for install directory
$defaultDir = Join-Path $HOME "Dev\claude-windows-setup"
Write-Host "Install directory: " -NoNewline
Write-Host $defaultDir -ForegroundColor Yellow
$inputDir = Read-Host "Press Enter to accept, or type a new path"
if ([string]::IsNullOrWhiteSpace($inputDir)) {
    $installDir = $defaultDir
} else {
    $installDir = $inputDir
}

# Create directory
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Write-Host "[OK] Created $installDir" -ForegroundColor Green
} else {
    Write-Host "[OK] Directory already exists: $installDir" -ForegroundColor Green
}

# Download and extract repo ZIP
$zipUrl = "https://github.com/kitaekatt/claude-windows-setup/archive/refs/heads/main.zip"
$zipPath = Join-Path $env:TEMP "claude-windows-setup.zip"
$extractPath = Join-Path $env:TEMP "claude-windows-setup-extract"

Write-Host "Downloading repository..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

Write-Host "Extracting..." -ForegroundColor Cyan
if (Test-Path $extractPath) {
    Remove-Item $extractPath -Recurse -Force
}
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

# GitHub ZIPs extract to a subfolder named {repo}-{branch}
$extractedFolder = Join-Path $extractPath "claude-windows-setup-main"
Copy-Item -Path "$extractedFolder\*" -Destination $installDir -Recurse -Force

# Clean up temp files
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "[OK] Repository installed to $installDir" -ForegroundColor Green
Write-Host ""

# Run the installer
$installer = Join-Path $installDir "bin\install-claude-code.bat"
Write-Host "Running installer..." -ForegroundColor Cyan
Write-Host ""
Set-Location $installDir
& cmd.exe /c $installer
