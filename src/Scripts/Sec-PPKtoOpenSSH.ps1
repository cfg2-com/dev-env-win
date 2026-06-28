<#
.SYNOPSIS
Converts PuTTY .ppk keys to OpenSSH format.

.DESCRIPTION
Accepts a single .ppk file or a folder containing .ppk files. By default,
converted keys are written next to the source file. Use -OutputDirectory to
write the converted file(s) to another folder.

.EXAMPLE
.\Sec-PPKtoOpenSSH.ps1 -Path .\id_rsa.ppk

.EXAMPLE
.\Sec-PPKtoOpenSSH.ps1 -Path .\keys -OutputDirectory .\openssh
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[Parameter(Mandatory = $true, Position = 0)]
	[string]$Path,

	[Parameter(Position = 1)]
	[string]$OutputDirectory,

	[switch]$Force
)

function Get-PPKFiles {
	param(
		[Parameter(Mandatory = $true)]
		[string]$InputPath
	)

	$resolvedPath = Resolve-Path -LiteralPath $InputPath -ErrorAction Stop
	$item = Get-Item -LiteralPath $resolvedPath.Path

	if ($item.PSIsContainer) {
		return Get-ChildItem -LiteralPath $item.FullName -Filter '*.ppk' -File
	}

	if ($item.Extension -ne '.ppk') {
		throw "Input path '$InputPath' is not a .ppk file or folder containing .ppk files."
	}

	return @($item)
}

$puttygen = Get-Command -Name 'puttygen.exe' -ErrorAction SilentlyContinue
if (-not $puttygen) {
	$puttygen = Get-Command -Name 'puttygen' -ErrorAction SilentlyContinue
}

if (-not $puttygen) {
	throw 'puttygen.exe was not found in PATH. Install PuTTY/puttygen before running this script.'
}

$ppkFiles = Get-PPKFiles -InputPath $Path
if (-not $ppkFiles) {
	throw "No .ppk files were found at '$Path'."
}

foreach ($ppkFile in $ppkFiles) {
	$destinationFolder = if ($OutputDirectory) {
		$OutputDirectory
	}
	else {
		$ppkFile.DirectoryName
	}

	if (-not (Test-Path -LiteralPath $destinationFolder)) {
		New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
	}

	$outputFile = Join-Path -Path $destinationFolder -ChildPath $ppkFile.BaseName

	if ((Test-Path -LiteralPath $outputFile) -and -not $Force) {
		throw "Output file '$outputFile' already exists. Use -Force to overwrite it."
	}

	if ($PSCmdlet.ShouldProcess($ppkFile.FullName, "Convert to OpenSSH key at '$outputFile'")) {
		& $puttygen.Path $ppkFile.FullName -O private-openssh -o $outputFile

		if ($LASTEXITCODE -ne 0) {
			throw "PuTTYgen failed while converting '$($ppkFile.FullName)'."
		}

		Write-Host "Converted '$($ppkFile.FullName)' to '$outputFile'."
	}
}
