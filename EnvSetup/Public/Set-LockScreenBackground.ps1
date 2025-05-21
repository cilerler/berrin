function Set-LockScreenBackground {
    [CmdletBinding()]
    param(
        [string]$ImagePath
    )

    # Validate path
    if ([string]::IsNullOrWhiteSpace($ImagePath) -or !(Test-Path $ImagePath)) {
        Write-Error "Invalid image path: $ImagePath"
        return
    }

    # Set registry keys for Lock screen
    $PersonalizePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

    # Create registry path if it doesn't exist
    if (!(Test-Path $PersonalizePath)) {
        New-Item -Path $PersonalizePath -Force | Out-Null
    }

    # Set registry values
    New-ItemProperty -Path $PersonalizePath -Name "LockScreenImagePath" -Value $ImagePath -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $PersonalizePath -Name "LockScreenImageUrl" -Value $ImagePath -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $PersonalizePath -Name "LockScreenImageStatus" -Value 1 -PropertyType DWORD -Force | Out-Null
}
