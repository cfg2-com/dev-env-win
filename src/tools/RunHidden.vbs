'
' Run a Windows Batch script (*.bat) or PowerShell script (*.ps1) from Windows Task Scheduler hidden (no flicker)
'
' In Windows Task Scheduler...
' Program/script: wscript.exe
' Add arguments: "%TOOLS_HOME%\RunHidden.vbs" "C:\Path\To\YourScript.bat" [script args...] [wait]
' Start in:	%TOOLS_HOME%
'
' Ensure both the path to the VBScript and the path to the target script are wrapped in double quotes in the arguments box.
' Windows expands %TOOLS_HOME% before Task Scheduler launches the action.
' When wscript.exe runs, it loads your VBScript. The script then looks at its own "Arguments" list, finds the path to your target file, and executes it with the 0 flag. The 0 flag is the magic instruction that tells Windows: "Run this, but do not create a window for it."
' If the target path ends in .ps1, the script runs it through powershell.exe -NoProfile -ExecutionPolicy Bypass -File.

If WScript.Arguments.Count >= 1 Then
    Set WinScriptHost = CreateObject("WScript.Shell")
    
    Dim shouldWait : shouldWait = False
    Dim targetPath : targetPath = WScript.Arguments(0)
    Dim commandLine : commandLine = ""
    Dim i
    
    ' Check if the second argument is "wait" (case-insensitive)
    If WScript.Arguments.Count >= 2 Then
        If LCase(WScript.Arguments(1)) = "wait" Then
            shouldWait = True
        End If
    End If
    
    If LCase(Right(targetPath, 4)) = ".ps1" Then
        commandLine = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File " & Chr(34) & targetPath & Chr(34)
        For i = 1 To WScript.Arguments.Count - 1
            If LCase(WScript.Arguments(i)) <> "wait" Then
                commandLine = commandLine & " " & Chr(34) & WScript.Arguments(i) & Chr(34)
            End If
        Next
    Else
        commandLine = Chr(34) & targetPath & Chr(34)
        For i = 1 To WScript.Arguments.Count - 1
            If LCase(WScript.Arguments(i)) <> "wait" Then
                commandLine = commandLine & " " & Chr(34) & WScript.Arguments(i) & Chr(34)
            End If
        Next
    End If

    ' Run the file: 0 = Hidden window style
    WinScriptHost.Run commandLine, 0, shouldWait
    
    Set WinScriptHost = Nothing
End If