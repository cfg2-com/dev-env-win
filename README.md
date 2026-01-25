# dev-env-win
Scripts and config for a Windows development environment

See the src folder for individual scripts

## Setup

The "startup" script is safe to rerun multiple times or enable any time you start your computer:

From PowerShell:
```
Copy-Item -Path "src\startup-dev-env-win.bat" -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\startup-dev-env-win.bat"
```

From the command prompt:
```
copy src\startup-dev-env-win.bat "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\startup-dev-env-win.bat"
```

If you want the settings to take effect immediately:

From PowerShell:
```
& "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\startup-dev-env-win.bat"

$env:CLOUD_HOME = [System.Environment]::GetEnvironmentVariable("CLOUD_HOME", "User")
```

From Command Prompt:
```
CALL "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\startup-dev-env-win.bat"
```

## Agentic Coding

This repo provides some basic agentic coding skills.

### Global Skills

While the `startup-dev-env-win.bat` creates a location and sets up symlinks for global skills, you still need to populate them (generally one time only). You can copy the skills in this repo with the following:

From PowerShell:
```
Copy-Item -Path "src\Agent\Skills\*" -Destination "$HOME\Agent\Skills" -Recurse -Force
```

From Command Prompt:
```
xcopy "src\Agent\Skills" "%USERPROFILE%\Agent\Skills" /E /I /Y
```

### Workspace Skills

If the "Global Skills" are not working/being recognized, you will likely need to create a workspace specific copy. 
To do that, copy `/src/setup-workspace.bat` to the root of your workspace and run it.
