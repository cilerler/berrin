function Initialize-OhMyPosh {
    [CmdletBinding()]
    param()

    Install-Module -Name Terminal-Icons -Repository PSGallery -Force;

    $ohMyPoshFilePath = "$env:userprofile\source\local\docs\oh-my-posh-theme.omp.json";
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wiki/cilerler/cilerler.github.io/documents/oh-my-posh-theme.omp.json" -OutFile $ohMyPoshFilePath;

    $profilePath = $PROFILE;

    # Ensure the profile file exists
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null;
    }

    # Define the lines to append
    $linesToAdd = @"
function prompt
{
    return;
}
Import-Module -Name Terminal-Icons;
oh-my-posh --init --shell pwsh --config "$ohMyPoshFilePath" | Invoke-Expression;
"@

    # Check if the lines already exist to avoid duplicates
    if (-not (Get-Content $profilePath | Select-String 'oh-my-posh')) {
        Add-Content -Path $profilePath -Value $linesToAdd;
    }
}
