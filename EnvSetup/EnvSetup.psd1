@{
    RootModule = 'EnvSetup.psm1'
    ModuleVersion = '1.0.0'
    GUID = '00000000-0000-0000-0000-000000000010'
    Author = 'Cengiz Ilerler'
    Description = 'Initial computer setup: folders, desktop cleanup, wallpaper, UI tweaks.'
    FunctionsToExport = @('Add-Folders', 'Add-QuickPins', 'Set-DesktopWallpaper', 'Set-LockScreenBackground', 'Hide-SearchBoxFromTaskbar', 'Remove-AllPublicDesktopShortcuts', 'Install-App', 'Initialize-DesktopEnvironment', 'Initialize-DesktopEnvironmentPowerShellCore', 'Install-WinGet', 'Install-PowerShellCore', 'Initialize-Terminal', 'Initialize-OhMyPosh', 'Enable-Features', 'Install-Terminal', 'Install-OhMyPosh')
}
