# Claude Windows Setup - Bootstrap Script
# Usage: irm https://raw.githubusercontent.com/kitaekatt/claude-windows-setup/main/setup.ps1 | iex

$ErrorActionPreference = "Stop"

# --- TEST FLAGS (set to $true to simulate failures) ---
$TEST_FAIL_NETWORK = $false
$TEST_FAIL_DOWNLOAD = $true
# --- END TEST FLAGS ---

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

# Prompt for setup directory
$defaultDir = Join-Path $HOME "claude-windows-setup"
Write-Host "Setup directory: " -NoNewline
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

# Check network connectivity
Write-Host "Checking network connectivity..." -ForegroundColor Cyan
$networkOk = $true
if ($TEST_FAIL_NETWORK) {
    $networkOk = $false
} else {
    try {
        $null = Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 10
    } catch {
        $networkOk = $false
    }
}
if ($networkOk) {
    Write-Host "[OK] Network connectivity confirmed" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Cannot reach github.com." -ForegroundColor Red
    Write-Host ""
    Write-Host "Diagnostics:" -ForegroundColor Yellow
    $adapter = Get-NetIPAddress -AddressFamily IPv4 -Type Unicast -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -ne '127.0.0.1' }
    if (-not $adapter) {
        Write-Host "  - No active network connection detected" -ForegroundColor Yellow
    } else {
        Write-Host "  - Network adapter connected (IP: $($adapter[0].IPAddress))" -ForegroundColor Yellow
        try {
            $null = Resolve-DnsName "github.com" -ErrorAction Stop
            Write-Host "  - DNS resolution: OK" -ForegroundColor Yellow
            Write-Host "  - HTTPS connection to github.com failed (may be blocked by firewall or proxy)" -ForegroundColor Yellow
        } catch {
            Write-Host "  - DNS resolution failed (cannot resolve github.com)" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    Write-Host "Please try again later." -ForegroundColor Red
    return
}
Write-Host ""

# Download and extract repo ZIP
$zipUrl = "https://github.com/kitaekatt/claude-windows-setup/archive/refs/heads/main.zip"
$zipPath = Join-Path $env:TEMP "claude-windows-setup.zip"
$extractPath = Join-Path $env:TEMP "claude-windows-setup-extract"

$maxRetries = 3
$downloaded = $false
for ($i = 1; $i -le $maxRetries; $i++) {
    try {
        Write-Host "Downloading repository (attempt $i of $maxRetries)..." -ForegroundColor Cyan
        if ($TEST_FAIL_DOWNLOAD) { $downloaded = $false; break }
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
        $downloaded = $true
        break
    } catch {
        Write-Host "[WARN] Download failed: $_" -ForegroundColor Yellow
        if ($i -lt $maxRetries) {
            Write-Host "Retrying..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }
}
if (-not $downloaded) {
    Write-Host "[ERROR] Download failed after $maxRetries attempts." -ForegroundColor Red
    Write-Host "Please try again later." -ForegroundColor Red
    return
}

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
