function Initialize-DesktopEnvironment {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BasePath,

        [Parameter()]
        [string]$DesktopWallpaperImagePath,

        [Parameter()]
        [string]$LockScreenImagePath,

        [Parameter()]
        [string]$TerminalBackgroundImagePath
    )

    Write-Verbose "Starting desktop environment initialization..."

    try {
        Write-Verbose "Setting desktop wallpaper to: $DesktopWallpaperImagePath"
        Set-DesktopWallpaper -ImagePath $DesktopWallpaperImagePath

        Write-Verbose "Setting lock screen background to: $LockScreenImagePath"
        Set-LockScreenBackground -ImagePath $LockScreenImagePath

        Write-Verbose "Hiding search box from taskbar..."
        Hide-SearchBoxFromTaskbar

        Write-Verbose "Removing public desktop shortcuts..."
        Remove-AllPublicDesktopShortcuts

        Write-Verbose "Creating standard folder structure..."
        Add-Folders

        Write-Verbose "Adding quick access pins..."
        Add-QuickPins

        # Requires elevated permissions
        # Write-Verbose "Enabling Windows features..."
        # Enable-Features

        Write-Verbose "Installing WinGet"
        Install-WinGet -BasePath $BasePath

        Write-Verbose "Installing PowerShell Core"
        Install-PowerShellCore -BasePath $BasePath

        Write-Verbose "Calling PowerShell Core script to initialize desktop environment..."
        pwsh.exe -ExecutionPolicy Bypass -Command "Import-Module '$env:userprofile\Source\github\cilerler\berrin\AllModules'; Initialize-DesktopEnvironmentPowerShellCore -BasePath '$BasePath' -TerminalBackgroundImagePath '$TerminalBackgroundImagePath'"
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red;
        Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow;
        Write-Host "Error Details:" -ForegroundColor Cyan;
        Write-Host "  Message: $($_.Exception.Message)";
        Write-Host "  Type: $($_.Exception.GetType().FullName)";
        Write-Host "  Line: $($_.InvocationInfo.ScriptLineNumber)";
        Write-Host "  Column: $($_.InvocationInfo.OffsetInLine)";
        Write-Host "  Script: $($_.InvocationInfo.ScriptName)";
    }

    Write-Verbose "Desktop environment initialization complete."
}
