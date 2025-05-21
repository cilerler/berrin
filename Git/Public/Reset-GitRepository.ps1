<#
.SYNOPSIS
    Resets the current Git repository while preserving remote URL and user configuration.

.DESCRIPTION
    Reset-GitRepository removes the existing .git folder, reinitializes the repository, restores the previous remote URL,
    and reapplies the user.name and user.email settings. All files are staged and committed as an initial commit, then
    force-pushed to the remote origin. This is useful for cleaning up repository history or reinitializing a project
    while keeping the remote and user configuration intact.

.EXAMPLE
    Reset-GitRepository
    Resets the current directory's Git repository, preserving remote and user config, and force-pushes to origin/main.

.NOTES
    Requires Git to be installed and available in the system PATH.
    The function will abort if no .git folder or remote URL is found.
#>
function Reset-GitRepository {
    [CmdletBinding()]
    param()

    # Check if .git folder exists
    if (-not (Test-Path -Path ".git" -PathType Container)) {
        Write-Error "No .git folder found in current directory. Exiting."
        return
    }

    # Extract the remote URL, username and email from git config
    $remoteUrl = git config --get remote.origin.url
    $userName = git config --get user.name
    $userEmail = git config --get user.email

    if ([string]::IsNullOrEmpty($remoteUrl)) {
        Write-Error "Could not find remote URL in git config. Exiting."
        return
    }

    # Store the configuration info
    Write-Output "Found remote URL: $remoteUrl"
    if (-not [string]::IsNullOrEmpty($userName)) {
        Write-Output "Found user name: $userName"
    }
    if (-not [string]::IsNullOrEmpty($userEmail)) {
        Write-Output "Found user email: $userEmail"
    }

    # Remove .git folder
    Remove-Item -Recurse -Force .git

    # Initialize new git repository
    git init

    # Set user name and email if found
    Set-GitUserConfig -RepoPath "." -GitUserName $userName -GitUserEmail $userEmail

    # Add all files
    git add .

    # Commit
    git commit -m "Initial commit"

    # Add remote
    git remote add origin $remoteUrl

    # Force push
    git push -u --force origin main

    Write-Output "Repository reset and pushed to $remoteUrl"
}
