function Install-WinGet {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BasePath
    )

    Install-App `
        -BasePath $BasePath `
        -AppName "winget" `
        -GitHubRepo "microsoft/winget-cli" `
        -AssetFilter "*.msixbundle" `
        -DependenciesFilter "*Dependencies.zip"
}
