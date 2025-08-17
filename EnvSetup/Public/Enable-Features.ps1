function Enable-Features {
    [CmdletBinding()]
    param()

    $features = @(
        "TelnetClient",
        "VirtualMachinePlatform",
        "Containers-DisposableClientVM",
        "Microsoft-Windows-Subsystem-Linux"
    )

    foreach ($feature in $features) {
        $featureState = Get-WindowsOptionalFeature -Online -FeatureName $feature
        if ($featureState.State -ne "Enabled") {
            Write-Host "Enabling $feature..."
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
        } else {
            Write-Host "$feature is already enabled."
        }
    }

    Write-Host "All requested features processed. A restart may be required."
}
