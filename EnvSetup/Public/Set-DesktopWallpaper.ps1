function Set-DesktopWallpaper {
    [CmdletBinding()]
    param(
        [string]$ImagePath
    )

    # Exit if ImagePath is empty or contains only whitespace
    if ([string]::IsNullOrWhiteSpace($ImagePath)) {
        Write-Verbose "Wallpaper path is empty or contains only whitespace. No action taken."
        return
    }

    # Update registry to change wallpaper
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -Name Wallpaper -Value $ImagePath

    # Refresh the desktop to apply wallpaper
    Add-Type @"
using System.Runtime.InteropServices;
public class Wallpaper {
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

    # Apply wallpaper
    [Wallpaper]::SystemParametersInfo(20, 0, $ImagePath, 3)
}
