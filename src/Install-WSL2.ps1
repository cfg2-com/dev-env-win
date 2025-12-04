# Requires Administrator privileges to run successfully.
# This script uses the modern 'wsl --install' command to enable WSL2,
# install the kernel, and install the default Linux distribution (Ubuntu LTS).

## --- Administrator Check and Relaunch ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-File `"$($myinvocation.MyCommand.Path)`""
    exit
}
## --- End Administrator Check ---

function Run-Command {
    param(
        [string]$Command,
        [string]$Description
    )
    Write-Host "--- $Description ---" -ForegroundColor Yellow
    try {
        Invoke-Expression $Command
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Command failed with exit code $LASTEXITCODE. Check the output for details."
        } else {
            Write-Host "Success!" -ForegroundColor Green
        }
    } catch {
        Write-Error "An error occurred while running command: $_"
    }
    Write-Host ""
}

# 1. Check for Windows Version Compatibility (Optional but good practice)
Write-Host "--- Checking Windows Version ---" -ForegroundColor Yellow
$osBuild = (Get-CimInstance Win32_OperatingSystem).BuildNumber
if ($osBuild -lt 19041) {
    Write-Warning "⚠️ Your Windows build ($osBuild) may be too old for the modern 'wsl --install' command. The manual installation method may be required."
    Write-Host ""
} else {
    Write-Host "✅ Windows build is compatible (>$osBuild)." -ForegroundColor Green
}

# 2. Install WSL and the Default Distribution (Ubuntu LTS)
# This command enables the necessary features, installs the kernel, sets WSL 2 as default,
# and installs the latest Ubuntu LTS distribution.

Run-Command -Command "wsl --install" -Description "Installing WSL2 and Default Ubuntu LTS Distribution"

# 3. Inform User About Reboot Requirement
Write-Host "🚨 **CRITICAL STEP:** The required features and Ubuntu LTS have been queued for installation." -ForegroundColor Red
Write-Host "You **MUST RESTART YOUR COMPUTER** now for the installation to complete and the Ubuntu setup to begin." -ForegroundColor Red
Write-Host "After restarting, Ubuntu will launch automatically to prompt you for a **username and password**." -ForegroundColor Red
Write-Host ""
Write-Host "You can manually reboot using the command: **Restart-Computer** (if you've saved this script)." -ForegroundColor Cyan

# 4. Final Steps and Instructions
Write-Host "--- Installation Instructions Summary ---" -ForegroundColor Yellow
Write-Host "* **RESTART YOUR PC IMMEDIATELY**." -ForegroundColor DarkCyan
Write-Host "* Ubuntu will launch after reboot. Follow the prompts to create your **UNIX username and password**." -ForegroundColor DarkCyan
Write-Host "* To check your installation, open PowerShell after reboot and run: **wsl -l -v**" -ForegroundColor DarkCyan
Write-Host "* The installed distribution name will likely be: **Ubuntu**" -ForegroundColor DarkCyan