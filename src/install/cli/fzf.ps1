# 1. Install fzf via winget if not present
if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Write-Host "Installing fzf via winget..." -ForegroundColor Cyan
    winget install --id Junegunn.fzf --source winget --accept-source-agreements --accept-package-agreements
    
    # Safely refresh PATH in session without duplicating entries
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path","Machine") -split ';'
    $userPath    = [System.Environment]::GetEnvironmentVariable("Path","User") -split ';'
    $env:Path    = ($machinePath + $userPath | Select-Object -Unique) -join ';'
} else {
    Write-Host "fzf is already installed." -ForegroundColor Green
}

# 2. Install PSFzf module if missing or update
if (-not (Get-Module -ListAvailable -Name PSFzf)) {
    Write-Host "Installing PSFzf module..." -ForegroundColor Cyan
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Module -Name PSFzf -Scope CurrentUser -AllowClobber -Force
} else {
    Write-Host "PSFzf module is already installed." -ForegroundColor Green
}

# 3. Ensure PowerShell Profile exists
if (-not (Test-Path -Path $PROFILE)) {
    Write-Host "Creating PowerShell profile..." -ForegroundColor Cyan
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# 4. Set up PSFzf in Profile (replaces old PSFzf block if present)
$profileBlock = @"
# --- fzf & PSFzf Integration ---
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
"@

$profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue

if ([string]::IsNullOrWhiteSpace($profileContent)) {
    Add-Content -Path $PROFILE -Value "`n$profileBlock"
    Write-Host "Added PSFzf bindings to profile." -ForegroundColor Green
} elseif ($profileContent -match '# --- fzf & PSFzf Integration ---[\s\S]*?(?=(\r?\n#|\Z))') {
    # Replace existing fzf block with updated configuration
    $updatedContent = $profileContent -replace '# --- fzf & PSFzf Integration ---[\s\S]*?(?=(\r?\n#|\Z))', $profileBlock.Trim()
    Set-Content -Path $PROFILE -Value $updatedContent
    Write-Host "Updated existing PSFzf configuration in profile." -ForegroundColor Green
} else {
    Add-Content -Path $PROFILE -Value "`n$profileBlock"
    Write-Host "Appended PSFzf bindings to profile." -ForegroundColor Green
}

# 5. Reload Profile for current session
. $PROFILE
Write-Host "`nSetup complete! You can now use Ctrl+T and Ctrl+R." -ForegroundColor Green