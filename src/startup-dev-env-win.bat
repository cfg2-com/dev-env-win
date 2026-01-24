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

REM =============================
REM --- Main Script Execution ---
REM =============================
:Main

REM 1. Define the base path (e.g., the user's home folder)
set "BASE_PATH=%USERPROFILE%"

echo Starting directory creation process in the base path: "%BASE_PATH%"

REM 2. Call the function for each directory you want to create

REM Creating "Dev" inside the user's home folder
call :CreateDir "%BASE_PATH%\Dev"

REM Creating a "Temp - Local" folder inside the user's home folder
call :CreateDir "%BASE_PATH%\Temp - Local"

REM Creating an "Agents" folder inside the user's home folder
call :CreateDir "%BASE_PATH%\Agents"

REM Creating an Agents "Skills" folder inside the user's home folder
call :CreateDir "%BASE_PATH%\Agents\Skills"

REM --- End of Script ---

echo.
echo All directory operations complete.
pause