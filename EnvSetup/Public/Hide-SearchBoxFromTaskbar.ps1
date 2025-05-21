function Hide-SearchBoxFromTaskbar {
    [CmdletBinding()]
    param()

    $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
    If (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    # 0 = Hide, 1 = Icon only, 2 = Search box, 3 = Icon + label
    Set-ItemProperty -Path $regPath -Name 'SearchboxTaskbarMode' -Type DWord -Value 0 -Force
}
