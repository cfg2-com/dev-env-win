# dev-env-win
Scripts and config for a Windows development environment

See the src folder for individual scripts

## Setup

The "startup" script is safe to rerun multiple time or enable any time you start your computer:

From the command prompt:
```
copy src\startup-dev-env-win.bat "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\startup-dev-env-win.bat"
```

From PowerShell:
```
Copy-Item -Path "src\startup-dev-env-win.bat" -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\startup-dev-env-win.bat"
```

If you want the settings to take effect immediately:

From Command Prompt:
```
CALL "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\startup-dev-env-win.bat"
```

From PowerShell:
```
& "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\startup-dev-env-win.bat"
```