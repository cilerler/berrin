function Install-Terminal {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BasePath,
        [Parameter()]
        [string]$TerminalBackgroundImagePath
    )

    Install-App `
        -BasePath $BasePath `
        -AppName "terminal" `
        -GitHubRepo "microsoft/terminal" `
        -AssetFilter "*_x64.zip" `
        -UseWingetFallback `
        -WingetId "Microsoft.WindowsTerminal" `
        -NoCleanup `
        -PostInstallAction {
        param($AppPath)
        Initialize-Terminal -AppPath "$AppPath" -TerminalBackgroundImagePath "$TerminalBackgroundImagePath"
    }
}
