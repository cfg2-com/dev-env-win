' Run a Windows Batch script (*.bat) from Windows Task Schedular hidden (no flicker)
'
' In Windows Task Schedular...
' Program/script: wscript.exe
' Add arguments: "C:\Path\To\RunHidden.vbs" "C:\Path\To\YourBatch.bat" [wait]
' Start in:	C:\Path\To\
'
' Ensure both the path to the VBScript and the path to the batch file are wrapped in double quotes in the arguments box.
' When wscript.exe runs, it loads your VBScript. The script then looks at its own "Arguments" list, finds the path to your batch file, and executes it with the 0 flag. The 0 flag is the magic instruction that tells Windows: "Run this, but do not create a window for it."

If WScript.Arguments.Count >= 1 Then
    Set WinScriptHost = CreateObject("WScript.Shell")
    
    Dim shouldWait : shouldWait = False
    
    ' Check if the second argument is "wait" (case-insensitive)
    If WScript.Arguments.Count >= 2 Then
        If LCase(WScript.Arguments(1)) = "wait" Then
            shouldWait = True
        End If
    End If
    
    ' Run the file: 0 = Hidden window style
    WinScriptHost.Run Chr(34) & WScript.Arguments(0) & Chr(34), 0, shouldWait
    
    Set WinScriptHost = Nothing
End If