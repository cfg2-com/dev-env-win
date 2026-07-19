<#
.SYNOPSIS
    Creates a directory junction pointing to an existing folder.

.DESCRIPTION
    Validates that ExistingDir and JunctionParent exist, then creates a junction
    in JunctionParent named JunctionName that points to ExistingDir. When
    JunctionName is omitted, the leaf folder name from ExistingDir is used.

.PARAMETER ExistingDir
    Path to the existing directory the junction should target.

.PARAMETER JunctionParent
    Path to the parent directory where the junction will be created.

.PARAMETER JunctionName
    Optional name for the junction. Defaults to the last folder name in ExistingDir.

.EXAMPLE
    .\FS-JunctionCreate.ps1 -ExistingDir "C:\Dev\my-project" -JunctionParent "C:\Links"

.EXAMPLE
    .\FS-JunctionCreate.ps1 -ExistingDir "C:\Dev\my-project" -JunctionParent "C:\Links" -JunctionName "project-link"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$ExistingDir,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [string]$JunctionParent,

    [Parameter(Mandatory = $false, Position = 2)]
    [string]$JunctionName
)

if (-not (Test-Path -LiteralPath $ExistingDir -PathType Container)) {
    throw "ExistingDir does not exist or is not a directory: $ExistingDir"
}

if (-not (Test-Path -LiteralPath $JunctionParent -PathType Container)) {
    throw "JunctionParent does not exist or is not a directory: $JunctionParent"
}

$targetPath = (Resolve-Path -LiteralPath $ExistingDir).Path

if ([string]::IsNullOrWhiteSpace($JunctionName)) {
    $JunctionName = Split-Path -Path $targetPath -Leaf

    if ([string]::IsNullOrWhiteSpace($JunctionName)) {
        throw "Could not determine a default junction name from ExistingDir: $ExistingDir"
    }
}

$junctionPath = Join-Path -Path $JunctionParent -ChildPath $JunctionName

if (Test-Path -LiteralPath $junctionPath) {
    Write-Host "Junction path already exists: $junctionPath"
} else {
    Write-Host "Creating junction '$junctionPath' -> '$targetPath'..."
    New-Item -Path $junctionPath -ItemType Junction -Target $targetPath | Out-Null

    Write-Host "Junction created: $junctionPath"
}