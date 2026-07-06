# Define where you want to store the rclone executable
$DestinationFolder = "$env:USERPROFILE\Bin"
$ZipPath = "$env:TEMP\rclone.zip"
$ExtractPath = "$env:TEMP\rclone_extracted"

# 1. Create the destination directory if it doesn't exist
if (!(Test-Path $DestinationFolder)) {
    New-Item -ItemType Directory -Force -Path $DestinationFolder | Out-Null
}

# 2. Download the latest stable 64-bit Windows zip file
echo "Downloading latest Rclone release..."
$DownloadUrl = "https://downloads.rclone.org/rclone-current-windows-amd64.zip"
Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath

# 3. Clean any old extraction temp folders and extract the zip
if (Test-Path $ExtractPath) { Remove-Item -Recurse -Force $ExtractPath }
echo "Extracting archive..."
Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath

# 4. Find the exe (it's nested inside a versioned folder) and move it to your destination
$RcloneExe = Get-ChildItem -Path $ExtractPath -Filter "rclone.exe" -Recurse | Select-Object -First 1
if ($RcloneExe) {
    Move-Item -Path $RcloneExe.FullName -Destination "$DestinationFolder\rclone.exe" -Force
    echo "Success! rclone.exe has been placed in: $DestinationFolder\rclone.exe"
} else {
    Write-Error "Failed to find rclone.exe inside the downloaded archive."
}

# 5. Cleanup temporary zip files
Remove-Item -Force $ZipPath
Remove-Item -Recurse -Force $ExtractPath