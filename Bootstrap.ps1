param (
    [Parameter()]
    [string]$ModuleRoot = $PSScriptRoot
)

# Import private functions
$PrivatePath = "$ModuleRoot\Private\*.ps1"
$Private = @(Get-ChildItem -Path $PrivatePath -ErrorAction SilentlyContinue)
if ($Private.Count -gt 0) {
    foreach($file in $Private) {
        try {
            . $file.FullName
        } catch {
            Write-ColorMessage "Import: Failed - $_" -Type Error
        }
    }
}

# Import public functions
$PublicPath = "$ModuleRoot\Public\*.ps1"
$Public = @(Get-ChildItem -Path $PublicPath -ErrorAction SilentlyContinue)
if ($Public.Count -gt 0) {
    foreach($file in $Public) {
        try {
            . $file.FullName
        } catch {
            Write-ColorMessage "Import: Failed - $_" -Type Error
        }
    }
}
