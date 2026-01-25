@echo off

goto :Main

REM ========================================
REM --- Function Definition (Subroutine) ---
REM ========================================
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
REM 1. Define the base path (e.g., the user's home folder)
REM --------------------------------
set "BASE_PATH=%USERPROFILE%"

echo Starting directory creation process in the base path: "%BASE_PATH%"

REM --------------------------------
REM 2. Create Required Directories
REM --------------------------------

call :CreateDir "%BASE_PATH%\Dev"

call :CreateDir "%BASE_PATH%\Temp - Local"

REM --------------------------------
REM 3. Handle CLOUD_HOME setup
REM --------------------------------

REM Check for CLOUD_HOME environment variable
call :SetupCloudHome

REM --------------------------------
REM 4. Setup DEV_HOME
REM --------------------------------
echo.
echo Setting DEV_HOME

if not defined DEV_HOME (
    setx DEV_HOME "%BASE_PATH%\Dev"
    set "DEV_HOME=%BASE_PATH%\Dev"
)
echo DEV_HOME is set to %DEV_HOME%

REM --------------------------------
REM 5. Setup Agentic Coding
REM --------------------------------
echo.
echo Creating Agent directory...

call :CreateDir "%BASE_PATH%\Agent"

call :CreateDir "%BASE_PATH%\Agent\Skills"

echo.
set "SOURCE_DIR=%BASE_PATH%\Agent\Skills"

:: Define the target agent folders
set "CLAUDE_DIR=%USERPROFILE%\.claude\skills"
set "GEMINI_DIR=%USERPROFILE%\.gemini\skills"
set "CURSOR_DIR=%USERPROFILE%\.cursor\skills"
set "COPILOT_DIR=%USERPROFILE%\.copilot\skills"

echo Linking Agent Skills

:: Function-like block to create junctions
for %%A in ("%CLAUDE_DIR%" "%GEMINI_DIR%" "%CURSOR_DIR%" "%COPILOT_DIR%") do (
    if not exist "%%~dpA" mkdir "%%~dpA"
    if exist "%%~A" (
        echo [SKIP] %%~A already exists. Delete it manually if you want to re-link.
    ) else (
        echo [LINKING] %%~A --^> %SOURCE_DIR%
        mklink /J "%%~A" "%SOURCE_DIR%"
    )
)

REM --- End of Script ---

echo.
REM echo All directory operations complete.
REM pause