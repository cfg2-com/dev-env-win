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

echo.
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
REM 2. Call the function for each directory you want to create
REM --------------------------------

REM Creating "Dev" inside the user's home folder
call :CreateDir "%BASE_PATH%\Dev"

REM Creating a "Temp - Local" folder inside the user's home folder
call :CreateDir "%BASE_PATH%\Temp - Local"

REM Creating an "Agents" folder inside the user's home folder
call :CreateDir "%BASE_PATH%\Agents"

REM Creating an Agents "Skills" folder inside the user's home folder
call :CreateDir "%BASE_PATH%\Agents\Skills"

REM Creating ".gemini" folder inside the user's home folder
call :CreateDir "%BASE_PATH%\.gemini"

REM Create directory junction for skills
if not exist "%BASE_PATH%\.gemini\skills" (
    echo Creating directory junction for skills...
    mklink /J "%BASE_PATH%\.gemini\skills" "%BASE_PATH%\Agents\Skills"
)

REM --------------------------------
REM 3. Handle CLOUD_HOME setup
REM --------------------------------

REM Check for CLOUD_HOME environment variable
call :SetupCloudHome

REM --- End of Script ---

echo.
REM echo All directory operations complete.
REM pause