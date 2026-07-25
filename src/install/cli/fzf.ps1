# 1. Install fzf via winget if not present
if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Write-Host "Installing fzf via winget..." -ForegroundColor Cyan
    winget install --id Junegunn.fzf --source winget --accept-source-agreements --accept-package-agreements
    # Refresh PATH in the current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "fzf is already installed." -ForegroundColor Green
}

# 2. Install PSFzf module
Write-Host "Installing PSFzf module..." -ForegroundColor Cyan
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name PSFzf -Scope CurrentUser -AllowClobber -Force

# 3. Ensure PowerShell Profile exists
if (-not (Test-Path -Path $PROFILE)) {
    Write-Host "Creating PowerShell profile..." -ForegroundColor Cyan
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# 4. Add PSFzf setup to Profile
$profileBlock = @"

# --- fzf & PSFzf Integration ---
Import-Module PSFzf
Set-PsFzfOption -PSReadlineKeyHandler
"@

$profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
if ($profileContent -notlike "*Import-Module PSFzf*") {
    Write-Host "Appending PSFzf bindings to profile..." -ForegroundColor Cyan
    Add-Content -Path $PROFILE -Value $profileBlock
    Write-Host "Profile updated successfully!" -ForegroundColor Green
} else {
    Write-Host "PSFzf is already configured in your profile." -ForegroundColor Yellow
}

# 5. Reload Profile for current session
. $PROFILE
Write-Host "`nSetup complete! You can now use fzf keybindings." -ForegroundColor Green