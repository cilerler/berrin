function Remove-AllPublicDesktopShortcuts {
    [CmdletBinding()]
    param()

    # Get current user's desktop path
    $userDesktop = [Environment]::GetFolderPath("Desktop")

    # Get public desktop path
    $publicDesktop = "$env:PUBLIC\Desktop"

    # Get all .lnk files in both locations
    $shortcuts = @()
    if (Test-Path $userDesktop) {
        $shortcuts += Get-ChildItem -Path $userDesktop -Filter '*.lnk' -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $publicDesktop) {
        $shortcuts += Get-ChildItem -Path $publicDesktop -Filter '*.lnk' -Force -ErrorAction SilentlyContinue
    }

    # Remove all found shortcuts
    foreach ($shortcut in $shortcuts) {
        try {
            Remove-Item -Path $shortcut.FullName -Force -ErrorAction Stop
        } catch {
            Write-Warning "Failed to remove $($shortcut.FullName): $_"
        }
    }
}
