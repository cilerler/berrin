function Install-PowerShellCore {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BasePath
    )

    Install-App `
        -BasePath $BasePath `
        -AppName "powershell" `
        -GitHubRepo "powershell/powershell" `
        -AssetFilter "*-win-x64.msi" `
        -UseWingetFallback `
        -WingetId "Microsoft.PowerShell"

    # Allow time for PATH update
    Start-Sleep -Seconds 2;
    # Refresh the PATH variable to include the new PowerShell installation
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}
