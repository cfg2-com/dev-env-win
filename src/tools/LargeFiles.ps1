Get-ChildItem -Path "." -Recurse -File | 
    Sort-Object Length -Descending | 
    Select-Object Name, @{Name="SizeMB";Expression={[math]::round($_.Length / 1MB, 2)}}, FullName -First 20 | 
    Format-Table -AutoSize