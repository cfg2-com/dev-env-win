<#
.SYNOPSIS
    Downloads a zip archive from a URL and extracts it to a destination folder.

.DESCRIPTION
    Fetches a zip file, stages it under $env:TEMP, extracts the archive, and copies
    all top-level items into -Destination (defaults to the current working directory).

    Zip layout is preserved as-is: a single root folder, multiple files, or a mix
    all land directly under -Destination. Callers handle renaming or restructuring.

.PARAMETER Uri
    URL of the zip archive to download.

.PARAMETER Destination
    Folder where extracted content is copied. Defaults to the current working
    directory. Created when missing.

.EXAMPLE
    .\Web-ZipExtract.ps1 -Uri 'https://example.com/archive.zip'

    Downloads and extracts into the current directory.

.EXAMPLE
    .\Web-ZipExtract.ps1 `
        -Uri 'https://github.com/cfg2-com/dev-env-win/archive/refs/heads/main.zip' `
        -Destination 'C:\Projects\my-repo\tools'

    Extracts archive contents into tools\.

.NOTES
    Requires PowerShell 5.1+ and network access to the download URL.
    Temporary download and extract files are removed when the script completes.
    Does not clear -Destination before copying; remove the folder first for a clean install.
#>

#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string]$Uri,

    [string]$Destination = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

$destinationRoot = [System.IO.Path]::GetFullPath($Destination)
$uriFileName = [System.IO.Path]::GetFileName(([uri]$Uri).AbsolutePath)
if ([string]::IsNullOrWhiteSpace($uriFileName)) {
    $uriFileName = 'download.zip'
}

$tempRoot = Join-Path $env:TEMP ("web-zip-extract-{0}" -f [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tempRoot $uriFileName
$extractDir = Join-Path $tempRoot 'extracted'

try {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }

    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

    Write-Host "Downloading $Uri ..."
    Invoke-WebRequest -Uri $Uri -OutFile $zipPath -UseBasicParsing

    Write-Host "Extracting to $extractDir ..."
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

    $extractedItems = @(Get-ChildItem -Path $extractDir -Force)
    if ($extractedItems.Count -eq 0) {
        throw "No files found after extracting $zipPath."
    }

    if (-not (Test-Path -LiteralPath $destinationRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
    }

    Write-Host "Installing to $destinationRoot ..."
    Copy-Item -Path (Join-Path $extractDir '*') -Destination $destinationRoot -Recurse -Force

    Write-Host "Installed to $destinationRoot"
    return $destinationRoot
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
