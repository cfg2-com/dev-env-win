<#
# Code in this file has been modified by Cursor.
.SYNOPSIS
    Downloads a Chrome Web Store extension as a CRX file and optionally unpacks it.

.DESCRIPTION
    Parses a Chrome Web Store detail URL to extract the 32-character extension ID,
    downloads the extension package from Google's update service, and by default
    unpacks the embedded ZIP payload into the output directory.

    The CRX file is always saved as <ExtensionId>.crx. When unpacking is enabled,
    extension source files (manifest.json, scripts, assets, etc.) are extracted
    alongside the CRX in the same folder. CRX2 and CRX3 packages are supported.

.PARAMETER Url
    Chrome Web Store detail URL for the extension.
    Example: https://chromewebstore.google.com/detail/avaya-click-to-dial/jpagimdcgihkhdkhoplpkhdjbpaflhec

.PARAMETER OutDirectory
    Directory where the CRX file is saved and, unless -NoUnpack is specified,
    where unpacked extension files are written. Created if it does not exist.
    Default: $HOME\Downloads

.PARAMETER NoUnpack
    Download the CRX only; skip extracting extension source files.

.EXAMPLE
    .\Web-DownloadBrowserExtCrx.ps1 `
        -Url "https://chromewebstore.google.com/detail/avaya-click-to-dial/jpagimdcgihkhdkhoplpkhdjbpaflhec"

    Downloads and unpacks the extension into the default Downloads folder.

.EXAMPLE
    .\Web-DownloadBrowserExtCrx.ps1 `
        -Url "https://chromewebstore.google.com/detail/avaya-click-to-dial/jpagimdcgihkhdkhoplpkhdjbpaflhec" `
        -OutDirectory ".temp\browser-extensions\aafd"

    Downloads and unpacks the extension into a project working folder.

.EXAMPLE
    .\Web-DownloadBrowserExtCrx.ps1 `
        -Url "https://chromewebstore.google.com/detail/avaya-click-to-dial/jpagimdcgihkhdkhoplpkhdjbpaflhec" `
        -OutDirectory ".temp\browser-extensions\aafd" `
        -NoUnpack

    Downloads only the CRX package without extracting its contents.
#>

param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Url,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$OutDirectory = "$HOME\Downloads",

    [Parameter(Mandatory = $false)]
    [switch]$NoUnpack
)

function Expand-CrxArchive {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CrxPath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    $bytes = [System.IO.File]::ReadAllBytes($CrxPath)
    $zipOffset = -1

    for ($i = 0; $i -lt ($bytes.Length - 4); $i++) {
        if ($bytes[$i] -eq 0x50 -and $bytes[$i + 1] -eq 0x4B -and $bytes[$i + 2] -eq 0x03 -and $bytes[$i + 3] -eq 0x04) {
            $zipOffset = $i
            break
        }
    }

    if ($zipOffset -lt 0) {
        throw "Could not locate ZIP payload in CRX file: $CrxPath"
    }

    $tempZip = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName() + '.zip')

    try {
        [System.IO.File]::WriteAllBytes($tempZip, $bytes[$zipOffset..($bytes.Length - 1)])
        Expand-Archive -Path $tempZip -DestinationPath $DestinationPath -Force
    }
    finally {
        if (Test-Path $tempZip) {
            Remove-Item $tempZip -Force
        }
    }
}

# Extract the 32-character extension ID using regex
if ($Url -match '/detail/[^/]+/([a-z]{32})' -or $Url -match '/detail/([a-z]{32})') {
    $ExtId = $Matches[1]
    Write-Host "Extracted Extension ID: $ExtId" -ForegroundColor Cyan

    # Ensure target directory exists
    if (-not (Test-Path -Path $OutDirectory)) {
        New-Item -ItemType Directory -Path $OutDirectory -Force | Out-Null
    }

    # Resolve full path to avoid issues with relative paths like "."
    $ResolvedDir = Convert-Path $OutDirectory
    $OutputPath = Join-Path $ResolvedDir "$ExtId.crx"

    # Construct the download URL
    $DownloadUrl = "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=130.0&acceptformat=crx2,crx3&x=id%3D${ExtId}%26uc"

    Write-Host "Downloading extension..." -ForegroundColor Yellow

    # Download the file
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $OutputPath -MaximumRedirection 5

    Write-Host "Saved to: $OutputPath" -ForegroundColor Green

    if (-not $NoUnpack) {
        Write-Host "Unpacking extension..." -ForegroundColor Yellow
        Expand-CrxArchive -CrxPath $OutputPath -DestinationPath $ResolvedDir
        Write-Host "Unpacked to: $ResolvedDir" -ForegroundColor Green
    }
} else {
    Write-Error "Could not parse a valid Chrome Web Store URL."
}
