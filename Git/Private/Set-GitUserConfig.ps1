function Set-GitUserConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepoPath,

        [Parameter(Mandatory=$false)]
        [string]$GitUserName,

        [Parameter(Mandatory=$false)]
        [string]$GitUserEmail,

        [Parameter(Mandatory=$false)]
        [string]$RepoType = "repository"
    )

    if ($GitUserName -or $GitUserEmail) {
        Write-ColorMessage "Configuring Git user settings for $RepoType" -Type Processing

        Push-Location $RepoPath
        try {
            if ($GitUserName) {
                Write-ColorMessage "Setting Git user.name to '$GitUserName' in $RepoType" -Type Info
                git config user.name "$GitUserName"
            }
            if ($GitUserEmail) {
                Write-ColorMessage "Setting Git user.email to '$GitUserEmail' in $RepoType" -Type Info
                git config user.email "$GitUserEmail"
            }

            Write-ColorMessage "Git user configuration completed for $RepoType" -Type Success
        }
        catch {
            Write-ColorMessage "Failed to set Git user configuration: $_" -Type Error
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-ColorMessage "No Git user configuration specified for $RepoType" -Type Debug
    }
}
