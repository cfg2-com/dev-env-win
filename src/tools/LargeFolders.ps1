Get-ChildItem -Directory | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{
        Name = $_.Name
        SizeGB = [math]::round($size / 1GB, 2)
    }
} | Sort-Object SizeGB -Descending