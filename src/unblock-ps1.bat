@echo off

REM Needed to unblock the PowerShell scripts in the TOOLS_HOME directory to allow them to run without security prompts.
REM This script should be run after the startup-dev-env-win.bat script has been executed.

powershell -NoProfile -Command "Unblock-File -Path '%TOOLS_HOME%\Env-Print.ps1'"
powershell -NoProfile -Command "Unblock-File -Path '%TOOLS_HOME%\FS-JunctionCreate.ps1'"
powershell -NoProfile -Command "Unblock-File -Path '%TOOLS_HOME%\FS-LargeFiles.ps1'"
powershell -NoProfile -Command "Unblock-File -Path '%TOOLS_HOME%\FS-LargeFolders.ps1'"
powershell -NoProfile -Command "Unblock-File -Path '%TOOLS_HOME%\Git-RepoRefresh.ps1'"
powershell -NoProfile -Command "Unblock-File -Path '%TOOLS_HOME%\Sec-PPKtoOpenSSH.ps1'"
powershell -NoProfile -Command "Unblock-File -Path '%TOOLS_HOME%\Web-ZipExtract.ps1'"
powershell -NoProfile -Command "Unblock-File -Path '%TOOLS_HOME%\Web-GetGitHubBranch.ps1'"

echo Scripts unblocked successfully!
pause