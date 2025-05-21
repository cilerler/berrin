function Add-QuickPins {
    [CmdletBinding()]
    param()

    $paths = @(
        "$env:userprofile\Source",
        "$env:userprofile\Source\local\!nuget",
        "$env:userprofile\.nuget",
        "$env:AppData\npm",
        "$env:userprofile\.docker\volumes",
        "$env:Temp"
    );
    $o = New-Object -ComObject Shell.Application;

    foreach ($path in $paths) {
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null;
        }

        $folder = $o.Namespace($path)
        if ($null -ne $folder) {
            $folder.Self.InvokeVerb("pintohome");
        }
    }
}
