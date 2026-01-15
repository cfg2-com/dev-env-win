Invoke-WebRequest -Uri "https://update.code.visualstudio.com/latest/win32-x64/stable" -OutFile "VSCodeSetup.exe"
Start-Process -FilePath "./VSCodeSetup.exe" -ArgumentList "/silent", "/mergetasks=!runcode" -Wait
