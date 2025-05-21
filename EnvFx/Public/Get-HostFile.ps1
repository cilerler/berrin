function Get-HostFile() {
    [CmdletBinding()]
    param ()

    $hostsPath = "C:\Windows\System32\drivers\etc\hosts"
    $content = Get-Content -Path $hostsPath -ErrorAction Stop
    return $content
}
