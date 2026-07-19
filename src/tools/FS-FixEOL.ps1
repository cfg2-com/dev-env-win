<#
.SYNOPSIS 
    Converts literal line endings in a file to actual line endings.

.DESCRIPTION
    This script reads a file and replaces literal escape sequences for line endings (e.g., "\r\n", "\n", "\r") 
    with their actual character representations. The updated content is then saved back to the file using UTF8 encoding.

.PARAMETER FilePath
    The path to the file that needs to be processed. This parameter is mandatory.

.EXAMPLE
    .\FS-FixEOL.ps1 -FilePath "C:\path\to\file.txt"
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath
)

if (-not (Test-Path $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

# Read the file as a single raw string
$content = Get-Content -Raw -Path $FilePath

# Swap literal escape text sequences out for actual characters
$content = $content -replace '\\r\\n', "`r`n"
$content = $content -replace '\\n', "`n"
$content =$content -replace '\\r', "`r"

# Save the updated content back to the file using UTF8 encoding
Set-Content -Path $FilePath -Value $content -Encoding UTF8

Write-Host "Successfully converted literal line endings in: $FilePath"