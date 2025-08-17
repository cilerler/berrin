function Initialize-Berrin {
    [CmdletBinding()]
    param()

    $profilePath = $PROFILE;

    # Ensure the profile file exists
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null;
    }

    # Define the lines to append
    $linesToAdd = @"
Import-Module "$env:userprofile\Source\github\cilerler\berrin\AllModules";
"@

    # Check if the lines already exist to avoid duplicates
    if (-not (Get-Content $profilePath | Select-String 'berrin')) {
        Add-Content -Path $profilePath -Value $linesToAdd;
    }
}
