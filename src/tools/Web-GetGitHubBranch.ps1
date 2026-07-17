<#
.SYNOPSIS
    Downloads a GitHub branch archive and extracts it to a destination folder.

.DESCRIPTION
    Builds the GitHub branch zip URL for the given project, repo, and branch, then
    delegates download and extraction to Web-ZipExtract.ps1.

    Zip layout is preserved as-is under -Destination. Callers handle renaming or
    restructuring (for example, GitHub archives extract as {repo}-{branch}).

.PARAMETER Project
    GitHub organization or user that owns the repository.

.PARAMETER Repo
    GitHub repository name.

.PARAMETER Branch
    Git branch to download.

.PARAMETER Destination
    Folder where extracted content is copied. Defaults to the current working
    directory.

.EXAMPLE
    .\Web-GetGitHubBranch.ps1 -Project 'cfg2-com' -Repo 'dev-env-win' -Branch 'main'

    Downloads and extracts into the current directory.

.EXAMPLE
    .\Web-GetGitHubBranch.ps1 `
        -Project 'cfg2-com' `
        -Repo 'dev-env-win' `
        -Branch 'main' `
        -Destination 'C:\Projects\my-repo\tools'

    Extracts archive contents into tools\.

.NOTES
    Requires PowerShell 5.1+ and network access to github.com.
    See Web-ZipExtract.ps1 for the generic download and extract implementation.
#>

#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string]$Project,

    [Parameter(Mandatory = $true)]
    [string]$Repo,

    [Parameter(Mandatory = $true)]
    [string]$Branch,

    [string]$Destination = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

$uri = "https://github.com/$Project/$Repo/archive/refs/heads/$Branch.zip"

& (Join-Path $PSScriptRoot 'Web-ZipExtract.ps1') `
    -Uri $uri `
    -Destination $Destination
