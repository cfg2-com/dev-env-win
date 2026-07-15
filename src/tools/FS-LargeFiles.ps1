<#
.SYNOPSIS
Lists the largest files under a directory.

.DESCRIPTION
Recursively scans a path (current directory by default), sorts files by size
descending, and prints the top results in a table with file name, size in MB,
and full path.

.PARAMETER Path
Root directory to scan. Defaults to the current directory.

.PARAMETER Top
Number of largest files to display. Defaults to 20.

.EXAMPLE
./FS-LargeFiles.ps1
Scans the current directory and shows the 20 largest files.

.EXAMPLE
./FS-LargeFiles.ps1 -Path .. -Top 50
Scans the parent directory and shows the 50 largest files.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Path = ".",

    [Parameter()]
    [ValidateRange(1, 10000)]
    [int]$Top = 20
)

Get-ChildItem -Path $Path -Recurse -File | 
    Sort-Object Length -Descending | 
    Select-Object Name, @{Name="SizeMB";Expression={[math]::round($_.Length / 1MB, 2)}}, FullName -First $Top | 
    Format-Table -AutoSize