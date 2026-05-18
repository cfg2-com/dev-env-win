<#
.SYNOPSIS
    Installs or upgrades PowerShell to the latest stable release using WinGet.
.DESCRIPTION
    Ensures that the latest version of PowerShell (Microsoft.PowerShell) is 
    installed, bypassing prompts and handling upgrades smoothly.
.NOTES
    You may need to run one of the following commands with administrative privileges to remove MSI-based installations of PowerShell 7.x before using this script:
    Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -match "PowerShell 7" } | Invoke-CimMethod -MethodName Uninstall
    or
    Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -match "PowerShell 7" } | ForEach-Object { $_.Uninstall() }
#>

# 1. Define the official PowerShell package ID
$packageId = "Microsoft.PowerShell"

Write-Host "Checking Windows Package Manager (winget)..." -ForegroundColor Cyan

# 2. Verify WinGet is available on the system
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning "WinGet is not detected on this system. Attempting to fallback to the official Microsoft MSI installer script..."
    # Fallback to the official web-based installer script from Microsoft if winget is missing
    Invoke-Expression "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet"
    exit
}

# 3. Check if PowerShell 7.x is already installed via WinGet
$checkPackage = winget list --id $packageId --exact | Out-String

if ($checkPackage -match $packageId) {
    Write-Host "PowerShell 7 is already installed. Checking for available upgrades..." -ForegroundColor Cyan
    
    # Run the silent upgrade command
    # --silent suppresses the GUI, --accept-source-agreements / --accept-package-agreements bypass prompts
    winget upgrade --id $packageId --silent --accept-source-agreements --accept-package-agreements
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PowerShell upgraded successfully or is already up to date!" -ForegroundColor Green
    } else {
        Write-Warning "WinGet upgrade completed with exit code: $LASTEXITCODE. It may already be at the latest version."
    }
} else {
    Write-Host "PowerShell 7 not detected. Performing a fresh install of the latest stable version..." -ForegroundColor Yellow
    
    # Perform a clean installation of the latest version
    winget install --id $packageId --silent --accept-source-agreements --accept-package-agreements
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PowerShell installed successfully!" -ForegroundColor Green
    } else {
        Write-Error "Failed to install PowerShell via WinGet."
    }
}