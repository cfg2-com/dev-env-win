<#
.SYNOPSIS
	Installs or upgrades PuTTY and ensures PuTTYgen is available on PATH.

.DESCRIPTION
	Uses WinGet to install or upgrade the official PuTTY package. After the
	package is installed, the script verifies that puttygen.exe exists and adds
	its install directory to the current user's PATH when needed so other
	scripts can call it directly.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param()

$packageId = 'PuTTY.PuTTY'
$executableName = 'puttygen.exe'

function Add-DirectoryToUserPath {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Directory
	)

	$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
	$pathEntries = @($userPath -split ';' | Where-Object { $_ })

	if ($pathEntries -contains $Directory) {
		return $false
	}

	$updatedPath = if ([string]::IsNullOrWhiteSpace($userPath)) {
		$Directory
	}
	else {
		"$userPath;$Directory"
	}

	[Environment]::SetEnvironmentVariable('Path', $updatedPath, 'User')

	if (-not (($env:Path -split ';') -contains $Directory)) {
		$env:Path = "$env:Path;$Directory"
	}

	return $true
}

function Find-PuttyGen {
	$command = Get-Command -Name $executableName -ErrorAction SilentlyContinue
	if ($command) {
		return $command.Path
	}

	$candidateDirectories = @(
		(Join-Path -Path $env:ProgramFiles -ChildPath 'PuTTY'),
		(Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'PuTTY'),
		(Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Programs\PuTTY')
	) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

	foreach ($directory in $candidateDirectories) {
		$candidate = Join-Path -Path $directory -ChildPath $executableName
		if (Test-Path -LiteralPath $candidate) {
			return $candidate
		}
	}

	return $null
}

Write-Host 'Checking Windows Package Manager (winget)...' -ForegroundColor Cyan

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
	throw 'WinGet is not available on this system. Install App Installer / WinGet, then rerun this script.'
}

$isInstalled = (winget list --id $packageId --exact | Out-String) -match $packageId

if ($isInstalled) {
	Write-Host 'PuTTY is already installed. Checking for available upgrades...' -ForegroundColor Cyan

	if ($PSCmdlet.ShouldProcess($packageId, 'Upgrade PuTTY via WinGet')) {
		winget upgrade --id $packageId --exact --silent --accept-source-agreements --accept-package-agreements
		if ($LASTEXITCODE -ne 0) {
			throw "WinGet failed to upgrade PuTTY. Exit code: $LASTEXITCODE"
		}
	}
}
else {
	Write-Host 'PuTTY is not installed. Installing the latest stable release...' -ForegroundColor Yellow

	if ($PSCmdlet.ShouldProcess($packageId, 'Install PuTTY via WinGet')) {
		winget install --id $packageId --exact --silent --accept-source-agreements --accept-package-agreements
		if ($LASTEXITCODE -ne 0) {
			throw "WinGet failed to install PuTTY. Exit code: $LASTEXITCODE"
		}
	}
}

$puttyGenPath = Find-PuttyGen

if (-not $puttyGenPath) {
	throw 'PuTTY installation completed, but puttygen.exe was not found. Verify the installation and rerun the script.'
}

$puttyDirectory = Split-Path -Path $puttyGenPath -Parent

if (Add-DirectoryToUserPath -Directory $puttyDirectory) {
	Write-Host "Added '$puttyDirectory' to the current user's PATH." -ForegroundColor Green
}
else {
	if (-not (($env:Path -split ';') -contains $puttyDirectory)) {
		$env:Path = "$env:Path;$puttyDirectory"
	}

	Write-Host "'$puttyDirectory' is already present in the current user's PATH." -ForegroundColor Cyan
}

Write-Host "PuTTY is ready. PuTTYgen is available at '$puttyGenPath'." -ForegroundColor Green
