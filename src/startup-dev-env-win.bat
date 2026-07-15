@echo off

goto :Main

REM ==========================================
REM --- Function Definitions (Subroutines) ---
REM ==========================================
:CreateDir
REM %~1 strips surrounding quotes from the argument
set "TARGET_DIR=%~1"

echo.
echo Attempting to create directory: "%TARGET_DIR%"

REM Check if the directory already exists
if exist "%TARGET_DIR%" (
    echo Directory **already exists**. Skipping creation.
) else (
    REM Create the directory
    mkdir "%TARGET_DIR%"
    
    REM Check if the creation was successful
    if exist "%TARGET_DIR%" (
        echo Success! Directory created.
    ) else (
        echo Error! **Failed** to create directory.
    )
)
REM Return control to where the subroutine was called
goto :eof

:SetupCloudHome
echo.
if defined CLOUD_HOME (
    echo CLOUD_HOME is set to %CLOUD_HOME%
    goto :eof
)

REM Check registry for CLOUD_HOME to handle stale command prompt sessions
for /f "tokens=2,*" %%A in ('reg query HKCU\Environment /v CLOUD_HOME 2^>nul') do (
    echo Found CLOUD_HOME in registry: "%%B"
    set "CLOUD_HOME=%%B"
    goto :eof
)

echo.
set "USER_CLOUD_PATH="
set /p "USER_CLOUD_PATH=Provide the full path to the root of your preferred cloud drive: "

if not "%USER_CLOUD_PATH%"=="" (
    if exist "%USER_CLOUD_PATH%" (
        echo Setting CLOUD_HOME to "%USER_CLOUD_PATH%"
        setx CLOUD_HOME "%USER_CLOUD_PATH%"
        set "CLOUD_HOME=%USER_CLOUD_PATH%"
    ) else (
        echo Error: The directory "%USER_CLOUD_PATH%" does not exist.
    )
)
goto :eof

REM =============================
REM --- Main Script Execution ---
REM =============================
:Main

REM --------------------------------
REM Define the base path (e.g., the user's home folder)
REM --------------------------------
set "BASE_PATH=%USERPROFILE%"
set "CUR_SCRIPT_DIR=%~dp0"

echo Starting directory creation process in the base path: "%BASE_PATH%"

REM --------------------------------
REM Create Required Directories
REM --------------------------------

call :CreateDir "%BASE_PATH%\Tools"

call :CreateDir "%BASE_PATH%\Dev"

call :CreateDir "%BASE_PATH%\TempLocal"

REM --------------------------------
REM Handle CLOUD_HOME setup
REM --------------------------------

REM Check for CLOUD_HOME environment variable
call :SetupCloudHome

REM --------------------------------
REM Setup DEV_HOME
REM --------------------------------
echo.
echo Setting DEV_HOME

if not defined DEV_HOME (
    setx DEV_HOME "%BASE_PATH%\Dev"
    set "DEV_HOME=%BASE_PATH%\Dev"
)
echo DEV_HOME is set to %DEV_HOME%

REM --------------------------------
REM Setup TOOLS_HOME
REM --------------------------------
echo.
echo Setting TOOLS_HOME

if not defined TOOLS_HOME (
    setx TOOLS_HOME "%BASE_PATH%\Tools"
    set "TOOLS_HOME=%BASE_PATH%\Tools"
)
echo TOOLS_HOME is set to %TOOLS_HOME%

REM --------------------------------
REM Put %TOOLS_HOME% in PATH
REM Intentionally using registry to get around 1024 char limit of setx
REM --------------------------------
echo.
echo Setting PATH

set "TOOLS_PATH=%TOOLS_HOME%"
echo %PATH% | findstr /i /c:"%TOOLS_PATH%" >nul
if errorlevel 1 (
    echo Adding "%TOOLS_PATH%" to PATH.
    reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "%PATH%;%TOOLS_PATH%" /f
    set "PATH=%PATH%;%TOOLS_PATH%"
) else (
    echo "%TOOLS_PATH%" already in PATH. Skipping.
)

REM --------------------------------
REM Copy tools from repo to %BASE_PATH%\Tools
REM --------------------------------
echo.
echo Copying files from "%CUR_SCRIPT_DIR%tools" to "%TOOLS_PATH%"
if exist "%CUR_SCRIPT_DIR%tools" (
    robocopy "%CUR_SCRIPT_DIR%tools" "%TOOLS_PATH%" /E /NFL /NDL /NJH /NJS /NP >nul
    if errorlevel 8 (
        echo Warning: Some files may not have copied successfully.
    ) else (
        echo Tools copied successfully.
    )
) else (
    echo Warning: Source folder "%CUR_SCRIPT_DIR%tools" was not found. Skipping copy.
)

REM --- End of Script ---

echo.
REM echo All directory operations complete.
REM pause