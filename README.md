# dev-env-win
Tools/Scripts and config for a Windows development environment

See the src folder for individual scripts

## Setup

The `.\src\startup-dev-env-win.bat` is safe to rerun multiple times or enable any time you start your computer:

By far the simplest setup to to simply add a shortcut to `src\startup-dev-env-win.bat` in your `shell:startup` folder.

Otherwise, if you want an independent copy, you can run the following:

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

## Details

When you run `\src\startup-dev-env-win.bat`, some directories and environement variables will be setup, and a few files copied to the directories as defined below.

### Directories

- `%USERPROFILE%\Dev`
    - Unless already set, `%DEV_HOME%` will point here.
- `%USERPROFILE%\Tools`
    - Unless already set, `%TOOLS_HOME%` will point here.
    - The contents of `src\tools` will be copied here.
    - The directory will be placed in your `%PATH%`
- `%USERPROFILE%\TempLocal`
    - A local (non-cloud) storage location.

### Environment Variables

- CLOUD_HOME
    - Stable root for your cloud drive provider of choice.
    - Doesn't matter if you use/prefer GDrive, OneDrive, Proton Drive, or other.
    - Some tools will reference this location.
- DEV_HOME 
    - Stable root for where you should checkout repositories to. 
    - Some tools will reference this if the tool is development related.
- TOOLS_HOME
    - Stable root for tools.
    - Some scripts will reference this (esp for `install` scripts)