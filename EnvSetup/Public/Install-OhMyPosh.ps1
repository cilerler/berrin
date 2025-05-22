function Install-OhMyPosh {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BasePath
    )

    Install-App `
        -BasePath $BasePath `
        -AppName "ohmyposh" `
        -GitHubRepo "JanDeDobbeleer/oh-my-posh" `
        -AssetFilter "*-x64.msi" `
        -UseWingetFallback `
        -WingetId "JanDeDobbeleer.OhMyPosh"
}
