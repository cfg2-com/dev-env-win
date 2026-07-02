<#
.SYNOPSIS
Converts PuTTY .ppk keys to OpenSSH format using Python and paramiko.

.DESCRIPTION
Accepts a single .ppk file or a folder containing .ppk files. By default,
converted keys are written next to the source file. Use -OutputDirectory to
write the converted file(s) to another folder.

Requires: Python 3.6+ with paramiko library installed.
Install: pip install paramiko

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

$puttygen = Get-Command -Name 'python' -ErrorAction SilentlyContinue
if (-not $puttygen) {
	$puttygen = Get-Command -Name 'python3' -ErrorAction SilentlyContinue
}

if (-not $puttygen) {
	throw 'Python 3 was not found in PATH. Install Python 3.6+ before running this script.'
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
		$pythonScript = @"
import sys
import os
try:
	from paramiko import RSAKey, DSSKey, ECDSAKey, Ed25519Key, PKey
	from paramiko.pkey import PKey
except ImportError:
	print("ERROR: paramiko library not found. Install it with: pip install paramiko")
	sys.exit(1)

ppk_file = r'$($ppkFile.FullName)'
output_file = r'$outputFile'

try:
	# Try to load the key with each supported key type
	key = None
	for key_class in [RSAKey, DSSKey, ECDSAKey, Ed25519Key]:
		try:
			key = key_class.from_private_key_file(ppk_file)
			break
		except:
			pass
	
	if key is None:
		print(f"ERROR: Could not load PPK file as a recognized key type")
		sys.exit(1)
	
	# Write the key in OpenSSH format
	key.write_private_key_file(output_file, password=None)
	print(f"Converted '{ppk_file}' to '{output_file}'")
	sys.exit(0)
except Exception as e:
	print(f"ERROR: {str(e)}")
	sys.exit(1)
"@

		$pythonScriptFile = [System.IO.Path]::GetTempFileName() + '.py'
		$pythonScript | Set-Content -LiteralPath $pythonScriptFile -Encoding UTF8

		try {
			$conversionOutput = & $puttygen.Path $pythonScriptFile 2>&1
			$conversionExitCode = $LASTEXITCODE

			if ($conversionExitCode -ne 0) {
				if (($conversionOutput | Out-String) -match 'paramiko library not found') {
					throw @"
The paramiko library is required but not installed.
Install it by running: pip install paramiko
Then rerun this script.
"@
				}

				throw "Conversion failed: $($conversionOutput | Out-String)"
			}

			Write-Host "Converted '$($ppkFile.FullName)' to '$outputFile'."
		}
		finally {
			if (Test-Path -LiteralPath $pythonScriptFile) {
				Remove-Item -LiteralPath $pythonScriptFile -Force
			}
		}
	}
}
