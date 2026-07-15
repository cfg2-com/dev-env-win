<#
.SYNOPSIS
Lists immediate child folders and their total recursive size in gigabytes.

.DESCRIPTION
Scans each directory in the current working directory, calculates the total size of all files
under each directory (recursively), and outputs a sorted table from largest to smallest.

.EXAMPLE
PS> .\FS-LargeFolders.ps1

Displays the size (GB) of each first-level folder under the current path.

.OUTPUTS
System.Management.Automation.PSCustomObject

Each object contains:
- Name   : Folder name
- SizeGB : Total size in gigabytes, rounded to 2 decimals

.NOTES
Run this script from the parent directory you want to analyze.
#>
Get-ChildItem -Directory | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{
        Name = $_.Name
        SizeGB = [math]::round($size / 1GB, 2)
    }
} | Sort-Object SizeGB -Descending