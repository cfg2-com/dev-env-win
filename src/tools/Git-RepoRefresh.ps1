<#
.SYNOPSIS
    Ensures GitHub repositories exist locally and refreshes or syncs them to main.

.DESCRIPTION
    Accepts a directory (defaults to DEV_HOME), one or more GitHub repository URLs,
    and an action: REFRESH or MAIN.

    For each URL, ensures {Directory}/{repoName} contains a Git repository with a
    matching origin. Clones when missing; prompts before deleting and re-cloning
    when the folder exists but is not a valid repo or has a mismatched origin.

    REFRESH hard-syncs the current branch to origin/<currentBranch>.
    MAIN hard-syncs to the repository default branch (main first, then detected).

.PARAMETER Action
    REFRESH - sync current branch to origin.
    MAIN    - switch to default branch and sync to origin.

.PARAMETER Directory
    Root directory containing repositories as {Directory}/{repoName}.
    Defaults to the DEV_HOME environment variable.

.PARAMETER RepoUrl
    One or more GitHub repository URLs (HTTPS or SSH).

.EXAMPLE
    .\Git-RepoRefresh.ps1 -Action REFRESH -RepoUrl "https://github.com/owner/repo.git"

.EXAMPLE
    .\Git-RepoRefresh.ps1 -Action MAIN -Directory "C:\Dev" -RepoUrl "https://github.com/owner/a.git", "https://github.com/owner/b.git"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('REFRESH', 'MAIN')]
    [string]$Action,

    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$RepoUrl,

    [Parameter(Mandatory = $false, Position = 2)]
    [string]$Directory
)

function Get-RepoNameFromUrl {
    param([string]$Url)

    $trimmed = $Url.TrimEnd('/')
    $name = [System.IO.Path]::GetFileNameWithoutExtension($trimmed)

    if ([string]::IsNullOrWhiteSpace($name)) {
        throw "Could not determine repository name from URL: $Url"
    }

    return $name
}

function Normalize-GitRemoteUrl {
    param([string]$Url)

    if ([string]::IsNullOrWhiteSpace($Url)) {
        return ''
    }

    $normalized = $Url.Trim().TrimEnd('/').ToLowerInvariant()

    if ($normalized -match '^git@([^:]+):(.+)$') {
        $path = $matches[2].TrimEnd('.git')
        return "$($matches[1])/$path"
    }

    if ($normalized -match '^ssh://git@([^/]+)/(.+)$') {
        $path = $matches[2].TrimEnd('.git')
        return "$($matches[1])/$path"
    }

    if ($normalized -match '^https?://(.+)$') {
        return $matches[1].TrimEnd('.git')
    }

    return $normalized.TrimEnd('.git')
}

function Get-GitRemoteOriginUrl {
    param([string]$RepoPath)

    $originUrl = git -C $RepoPath remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    return $originUrl.Trim()
}

function Test-OriginMatchesUrl {
    param(
        [string]$OriginUrl,
        [string]$ExpectedUrl
    )

    if ([string]::IsNullOrWhiteSpace($OriginUrl)) {
        return $false
    }

    return (Normalize-GitRemoteUrl -Url $OriginUrl) -eq (Normalize-GitRemoteUrl -Url $ExpectedUrl)
}

function Invoke-GitCommand {
    param(
        [string]$RepoPath,
        [Parameter(Mandatory = $true)]
        [string[]]$GitArgs
    )

    if ($RepoPath) {
        & git -C $RepoPath @GitArgs
    }
    else {
        & git @GitArgs
    }

    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE."
    }
}

function Set-GitNonInteractive {
    $script:PreviousGitTerminalPrompt = $env:GIT_TERMINAL_PROMPT
    $script:PreviousGitAskYesNo = $env:GIT_ASKYESNO
    $env:GIT_TERMINAL_PROMPT = '0'
    $env:GIT_ASKYESNO = 'false'
}

function Restore-GitInteractive {
    if ($null -eq $script:PreviousGitTerminalPrompt) {
        Remove-Item Env:GIT_TERMINAL_PROMPT -ErrorAction SilentlyContinue
    }
    else {
        $env:GIT_TERMINAL_PROMPT = $script:PreviousGitTerminalPrompt
    }

    if ($null -eq $script:PreviousGitAskYesNo) {
        Remove-Item Env:GIT_ASKYESNO -ErrorAction SilentlyContinue
    }
    else {
        $env:GIT_ASKYESNO = $script:PreviousGitAskYesNo
    }
}

function Confirm-YesNo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )

    while ($true) {
        $response = Read-Host "$Prompt [y/n]"
        switch ($response.ToLowerInvariant()) {
            'y' { return $true }
            'yes' { return $true }
            'n' { return $false }
            'no' { return $false }
            default { Write-Host "Please enter y or n." }
        }
    }
}

function Remove-RepoDirectory {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

function Invoke-GitAbortMergeRebase {
    param([string]$RepoPath)

    $gitDir = Join-Path $RepoPath '.git'

    if (Test-Path -LiteralPath (Join-Path $gitDir 'MERGE_HEAD')) {
        Write-Host "Aborting in-progress merge..."
        Invoke-GitCommand -RepoPath $RepoPath -GitArgs @('merge', '--abort')
    }

    if ((Test-Path -LiteralPath (Join-Path $gitDir 'rebase-merge')) -or
        (Test-Path -LiteralPath (Join-Path $gitDir 'rebase-apply'))) {
        Write-Host "Aborting in-progress rebase..."
        Invoke-GitCommand -RepoPath $RepoPath -GitArgs @('rebase', '--abort')
    }
}

function Test-RemoteBranchExists {
    param(
        [string]$RepoPath,
        [string]$BranchName
    )

    git -C $RepoPath rev-parse --verify "origin/$BranchName" 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Get-CurrentBranchName {
    param([string]$RepoPath)

    $branch = git -C $RepoPath rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Could not determine current branch in $RepoPath."
    }

    if ($branch -eq 'HEAD') {
        throw "Repository is in detached HEAD state: $RepoPath. Checkout a branch before using REFRESH."
    }

    return $branch
}

function Get-DefaultBranchName {
    param([string]$RepoPath)

    if (Test-RemoteBranchExists -RepoPath $RepoPath -BranchName 'main') {
        return 'main'
    }

    $symbolicRef = git -C $RepoPath symbolic-ref refs/remotes/origin/HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($symbolicRef)) {
        if ($symbolicRef -match '^refs/remotes/origin/(.+)$') {
            return $matches[1]
        }
    }

    $remoteShow = git -C $RepoPath remote show origin 2>$null
    if ($LASTEXITCODE -eq 0) {
        foreach ($line in $remoteShow) {
            if ($line -match '^\s*HEAD branch:\s*(.+)\s*$') {
                return $matches[1].Trim()
            }
        }
    }

    throw "Could not determine default branch for $RepoPath."
}

function Sync-BranchHard {
    param(
        [string]$RepoPath,
        [string]$BranchName
    )

    Write-Host "Syncing $BranchName to origin/$BranchName in $RepoPath..."

    Invoke-GitCommand -RepoPath $RepoPath -GitArgs @(
        'fetch', 'origin', $BranchName, '--no-tags', '--no-auto-gc'
    )
    Invoke-GitAbortMergeRebase -RepoPath $RepoPath
    Invoke-GitCommand -RepoPath $RepoPath -GitArgs @(
        'checkout', '-B', $BranchName, "origin/$BranchName"
    )
}

function Invoke-RepoClone {
    param(
        [string]$RepoUrl,
        [string]$TargetPath
    )

    Write-Host "Cloning $RepoUrl to $TargetPath..."
    Invoke-GitCommand -RepoPath $null -GitArgs @('clone', $RepoUrl, $TargetPath)
}

function Ensure-Repository {
    param(
        [string]$RepoUrl,
        [string]$BaseDirectory
    )

    $repoName = Get-RepoNameFromUrl -Url $RepoUrl
    $targetPath = Join-Path -Path $BaseDirectory -ChildPath $repoName

    if (-not (Test-Path -LiteralPath $targetPath)) {
        Invoke-RepoClone -RepoUrl $RepoUrl -TargetPath $targetPath
        return $targetPath
    }

    $gitDir = Join-Path $targetPath '.git'
    $needsReclone = $false
    $reason = ''

    if (-not (Test-Path -LiteralPath $gitDir)) {
        $needsReclone = $true
        $reason = 'folder exists but is not a Git repository'
    }
    else {
        $originUrl = Get-GitRemoteOriginUrl -RepoPath $targetPath
        if (-not (Test-OriginMatchesUrl -OriginUrl $originUrl -ExpectedUrl $RepoUrl)) {
            $needsReclone = $true
            $reason = "origin URL does not match (origin: $originUrl, expected: $RepoUrl)"
        }
    }

    if ($needsReclone) {
        Write-Host ""
        Write-Host "Repository path requires re-clone: $targetPath"
        Write-Host "Reason: $reason"
        if (-not (Confirm-YesNo -Prompt 'Delete existing contents and clone?')) {
            Write-Warning "Skipping $repoName`: user declined re-clone."
            return $null
        }

        Remove-RepoDirectory -Path $targetPath
        Invoke-RepoClone -RepoUrl $RepoUrl -TargetPath $targetPath
    }

    return $targetPath
}

function Invoke-RepositoryAction {
    param(
        [string]$RepoPath,
        [string]$ActionName
    )

    switch ($ActionName) {
        'REFRESH' {
            $branchName = Get-CurrentBranchName -RepoPath $RepoPath
            Sync-BranchHard -RepoPath $RepoPath -BranchName $branchName
        }
        'MAIN' {
            Invoke-GitCommand -RepoPath $RepoPath -GitArgs @(
                'fetch', 'origin', '--no-tags', '--no-auto-gc'
            )
            Invoke-GitAbortMergeRebase -RepoPath $RepoPath
            $branchName = Get-DefaultBranchName -RepoPath $RepoPath
            Sync-BranchHard -RepoPath $RepoPath -BranchName $branchName
        }
    }

    Write-Host "Sync complete: $RepoPath"
}

function Resolve-BaseDirectory {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = $env:DEV_HOME
    }

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Directory not specified and DEV_HOME environment variable is not set.'
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Directory does not exist: $Path"
    }

    return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is not installed or not available on PATH.'
}

$baseDirectory = Resolve-BaseDirectory -Path $Directory
$failures = [System.Collections.Generic.List[string]]::new()
$processedUrls = @($RepoUrl | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

if ($processedUrls.Count -eq 0) {
    throw 'At least one RepoUrl is required.'
}

Set-GitNonInteractive
try {
    foreach ($url in $processedUrls) {
        Write-Host ""
        Write-Host "=== Processing $url ==="

        try {
            $repoPath = Ensure-Repository -RepoUrl $url -BaseDirectory $baseDirectory
            if ($null -eq $repoPath) {
                continue
            }

            Invoke-RepositoryAction -RepoPath $repoPath -ActionName $Action
        }
        catch {
            $message = $_.Exception.Message
            Write-Error "Failed processing $url`: $message"
            $failures.Add($url)

            if (-not (Confirm-YesNo -Prompt 'Continue with remaining repositories?')) {
                break
            }
        }
    }
}
finally {
    Restore-GitInteractive
}

Write-Host ""
if ($failures.Count -gt 0) {
    Write-Host "Completed with $($failures.Count) failure(s):"
    foreach ($failedUrl in $failures) {
        Write-Host "  - $failedUrl"
    }
    exit 1
}

Write-Host 'All repositories processed successfully.'
exit 0
