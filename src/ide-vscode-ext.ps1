# Can be run multiple times without issues
# To view the details of any of these extensions, visit https://marketplace.visualstudio.com/items?itemName=<extension-identifier>
# Feel free to comment out any extensions you do not wish to install

$extensions = @(
                "ms-dotnettools.csdevkit", 
                "ms-dotnettools.csharp", 
                "GitHub.copilot-chat",
                "Google.geminicodeassist",
                "Google.gemini-cli-vscode-ide-companion", 
                "ms-python.python", 
                "ms-vscode.PowerShell",
                "ms-vscode.vscode-speech",
                "redhat.java",
                "vscjava.vscode-maven",
                "vscjava.vscode-java-dependency",
                "vscjava.vscode-java-test",
                "mechatroner.rainbow-csv",
                "bmewburn.vscode-intelephense-client"
                )
foreach ($ext in $extensions) {
    code --install-extension $ext --force
}
