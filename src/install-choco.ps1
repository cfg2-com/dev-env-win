# install-choco.ps1
# Auto-elevates to Administrator if needed

Write-Host "Chocolatey Installation Script" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-NOT $isAdmin) {
    Write-Host "Elevation required. Relaunching as Administrator..." -ForegroundColor Yellow
    
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) {
        $scriptPath = $MyInvocation.InvocationName
    }
    
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit 0
}

Write-Host "Running as Administrator ✓" -ForegroundColor Green

# Check if Chocolatey is already installed
if (Get-Command "choco" -ErrorAction SilentlyContinue) {
    $version = choco -v
    Write-Host "Chocolatey is already installed (version: $version). Skipping installation." -ForegroundColor Yellow
    exit 0
}

# Prerequisites Check
Write-Host "`nChecking prerequisites..." -ForegroundColor Cyan

# Set TLS 1.2 for compatibility
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Set execution policy for this process only
Set-ExecutionPolicy Bypass -Scope Process -Force

# Install Chocolatey
Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan

try {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey installation completed successfully!" -ForegroundColor Green
} catch {
    Write-Error "Installation failed: $_" -ErrorAction Stop
}

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
[System.Collections.ArrayList]$envPaths = $env:Path.Split(';')
[array]$uniquePaths = $envPaths | Sort-Object -Unique
$env:Path = $uniquePaths -join ';'

# Verification
Write-Host "`nVerifying installation..." -ForegroundColor Cyan

if (Get-Command "choco" -ErrorAction SilentlyContinue) {
    $chocoVersion = choco -v
    $installPath = $env:ChocolateyInstall ?? "C:\ProgramData\chocolatey"
    Write-Host "✓ Chocolatey v$chocoVersion installed successfully at: $installPath" -ForegroundColor Green
    Write-Host "✓ Run 'choco --version' or 'choco -?' to get started." -ForegroundColor Green
} else {
    Write-Error "Chocolatey verification failed - command not found. Close and reopen PowerShell as Administrator." -ErrorAction Stop
}

Write-Host "`nInstallation complete! Restart PowerShell for full PATH recognition." -ForegroundColor Green[page:1]
