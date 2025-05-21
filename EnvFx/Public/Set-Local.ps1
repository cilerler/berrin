function Set-Local() {
    [CmdletBinding()]
    param ()

    Set-Location "$env:USERPROFILE\Source\local";
}
