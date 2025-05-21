function Remove-History() {
    [CmdletBinding()]
    param ()

    Remove-Item (Get-PSReadlineOption).HistorySavePath;
    Clear-History;
}
