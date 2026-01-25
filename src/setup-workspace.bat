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

set "DEFAULT_DIR=%CD%"
echo.
set /p "WORK_DIR=Enter base directory (default: %DEFAULT_DIR%): "
if "%WORK_DIR%"=="" set "WORK_DIR=%DEFAULT_DIR%"

REM Remove quotes if present
set "WORK_DIR=%WORK_DIR:"=%"

if not exist "%WORK_DIR%" (
    echo Error: Directory "%WORK_DIR%" does not exist.
    goto :eof
)

REM Creating "_agent-skills" inside the target folder
set "SKILLS_DIR=%WORK_DIR%\_agent-skills"
call :CreateDir "%SKILLS_DIR%"

echo.
echo Copying skills (skipping existing files)...
REM Robocopy flags: /E (recursive), /XC /XN /XO (exclude changed/newer/older = no overwrite), /R:0 /W:0 (no retry)
robocopy "%USERPROFILE%\Agents\Skills" "%SKILLS_DIR%" /E /XC /XN /XO /R:0 /W:0
