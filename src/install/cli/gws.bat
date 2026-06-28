@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "BIN_DIR=%USERPROFILE%\Bin"
set "TEMP_DIR=%TEMP%\gws-install"
set "ARCH=%PROCESSOR_ARCHITECTURE%"

if /I "%ARCH%"=="AMD64" (
	set "ASSET_FILE=google-workspace-cli-x86_64-pc-windows-msvc.zip"
) else if /I "%ARCH%"=="ARM64" (
	set "ASSET_FILE=google-workspace-cli-aarch64-pc-windows-msvc.zip"
) else (
	echo Unsupported architecture: %ARCH%
	echo This installer currently supports AMD64 and ARM64.
	exit /b 1
)

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

set "ASSET_URL=https://github.com/googleworkspace/cli/releases/latest/download/%ASSET_FILE%"

set "ZIP_PATH=%TEMP_DIR%\gws.zip"
set "EXTRACT_DIR=%TEMP_DIR%\extract"

if exist "%ZIP_PATH%" del /f /q "%ZIP_PATH%" >nul 2>&1
if exist "%EXTRACT_DIR%" rmdir /s /q "%EXTRACT_DIR%" >nul 2>&1

echo Downloading: %ASSET_URL%
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri '%ASSET_URL%' -OutFile '%ZIP_PATH%' -UseBasicParsing } catch { Write-Error $_; exit 1 }"
if errorlevel 1 (
	echo Failed to download gws release archive.
	exit /b 1
)

echo Extracting archive...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%EXTRACT_DIR%' -Force } catch { Write-Error $_; exit 1 }"
if errorlevel 1 (
	echo Failed to extract gws archive.
	exit /b 1
)

set "GWS_EXE_PATH="
for /f "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$exe = Get-ChildItem -Path '%EXTRACT_DIR%' -Recurse -File -Filter 'gws.exe' | Select-Object -First 1 -ExpandProperty FullName; if ($exe) { Write-Output $exe } else { exit 1 }"`) do (
	set "GWS_EXE_PATH=%%P"
)

if "%GWS_EXE_PATH%"=="" (
	echo Could not find gws.exe in extracted archive.
	exit /b 1
)

copy /y "%GWS_EXE_PATH%" "%BIN_DIR%\gws.exe" >nul
if errorlevel 1 (
	echo Failed to copy gws.exe to "%BIN_DIR%".
	exit /b 1
)

echo Installed gws.exe to "%BIN_DIR%\gws.exe"
echo.
echo To verify, run:
echo   "%BIN_DIR%\gws.exe" --version

endlocal
exit /b 0
