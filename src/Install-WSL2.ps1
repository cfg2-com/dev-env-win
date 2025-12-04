# WSL2 Installation Script (Fixed)
# Run as Administrator
# Script runs wsl --install ✅ (features enabled)
# Restart required ✅
# Launch Ubuntu from Start Menu (downloads/installs distro) ✅
# Re-run script (converts to WSL2) ✅
# Corrected: --set-default-version works separately, not with --install [web:3]

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Relaunching as Administrator..."
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Update WSL to latest version
Write-Host "Updating WSL..." -ForegroundColor Green
wsl --update

# Install WSL (enables features and installs default Ubuntu)
Write-Host "Installing WSL with default Ubuntu..." -ForegroundColor Green
wsl --install

# Set WSL2 as default version (separate command)
Write-Host "Setting WSL2 as default version..." -ForegroundColor Green
wsl --set-default-version 2

# Convert default distro to WSL2 if needed
Write-Host "Converting default distribution to WSL2..." -ForegroundColor Green
wsl --set-version $(wsl -l -q | Select-Object -First 1) 2

# Prompt for restart
Write-Host "WSL2 setup completed. Restart required." -ForegroundColor Yellow
$restart = Read-Host "Restart now? (Y/N)"
if ($restart -eq 'Y' -or $restart -eq 'y') {
    Restart-Computer -Force
}

Write-Host "Post-restart: 'wsl --list --verbose' should show VERSION 2" -ForegroundColor Cyan
