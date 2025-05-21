<#
.SYNOPSIS
    Creates or clones a Git repository in a standardized folder structure.

.DESCRIPTION
    New-BareRepository creates a bare Git repository under
    $RootFolder\local\_git-bare\<RepositoryPath>, and (if requested)
    clones or initializes a working repo, sets Git user config,
    and can make an initial commit.

.PARAMETER RepositoryPath
    Relative path (under $RootFolder) where the bare repository is created.

.PARAMETER WorkingRepoPath
    Optional absolute path for the working repository.
    If omitted, derives from $RootFolder and RepositoryPath.

.PARAMETER Clone
    If specified, performs a git clone (or init/clone depending on
    existing content) of the bare repository.

.PARAMETER InitialCommit
    When used with -Clone, stages, commits and pushes existing files
    to the new bare repository.

.PARAMETER GitUserName
    Value for user.name in the new repository's git config.

.PARAMETER GitUserEmail
    Value for user.email in the new repository's git config.

.EXAMPLE
    New-BareRepository -RepositoryPath "\UserSecrets" -Clone -InitialCommit -WorkingRepoPath "C:\Users\ciler\AppData\Roaming\Microsoft\UserSecrets"

.EXAMPLE
    New-BareRepository -RepositoryPath "\local\knowledgebase\personal" -Clone -InitialCommit -GitUserName "John Doe" -GitUserEmail "john.doe@example.com"
    Creates a bare Git repository at `$env:USERPROFILE\Source\local\_git-bare\local\knowledgebase\personal` and optionally clones it.
    Sets the Git user name and email for the bare repository.

.INPUTS
    None. Does not accept pipeline input.

.OUTPUTS
    None. Writes status messages and errors to the host.

.NOTES
    Requires Git be installed and on the PATH.
#>
function New-BareRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$RootFolder = "$env:USERPROFILE\Source",

        [Parameter(Mandatory=$true)]
        [string]$RepositoryPath,

        [Parameter(Mandatory=$false)]
        [string]$WorkingRepoPath, 

        [Parameter(Mandatory=$false)]
        [switch]$Clone,
        
        [Parameter(Mandatory=$false)]
        [switch]$InitialCommit,
        
        [Parameter(Mandatory=$false)]
        [string]$GitUserName,
        
        [Parameter(Mandatory=$false)]
        [string]$GitUserEmail
    )
    
    $ErrorActionPreference = 'Stop'

    # Validate parameters
    if ($InitialCommit -and -not $Clone) {
        Write-ColorMessage "The parameter -InitialCommit can only be used when -Clone is specified." -Type Error
        throw "The parameter -InitialCommit can only be used when -Clone is specified."
    }

    # Ensure repository path is relative
    if ($RepositoryPath.StartsWith('\')) {
        $RepositoryPath = $RepositoryPath.Substring(1)
    }
    
    # Derive paths
    $bareRepoPath = Join-Path -Path $RootFolder -ChildPath "local\_git-bare\$RepositoryPath"
    
    # Determine working repository path - use provided absolute path or derive from root folder
    if ($WorkingRepoPath) {
        # Use the absolute path provided
        $workingRepoPath = $WorkingRepoPath
    } else {
        # Use the default path derivation
        $workingRepoPath = Join-Path -Path $RootFolder -ChildPath $RepositoryPath
    }
    
    Write-ColorMessage "Repository configuration:" -Type Highlight
    Write-ColorMessage "  Bare repository path: $bareRepoPath" -Type Info
    Write-ColorMessage "  Working repository path: $workingRepoPath" -Type Info
    
    # Create the parent directories if they don't exist
    $bareRepoParent = Split-Path -Path $bareRepoPath -Parent
    if (-not (Test-Path -Path $bareRepoParent)) {
        Write-ColorMessage "Creating directory $bareRepoParent" -Type Processing
        New-Item -Path $bareRepoParent -ItemType Directory -Force | Out-Null
    }
    
    # Check if bare repository already exists
    if (Test-Path -Path $bareRepoPath) {
        Write-ColorMessage "Bare repository already exists at $bareRepoPath" -Type Error
        throw "Bare repository already exists at $bareRepoPath"
    }
    
    # Create bare Git repository
    Write-ColorMessage "Creating bare Git repository at $bareRepoPath" -Type Processing
    git init --bare $bareRepoPath
    
    # Configure Git user settings for bare repository
    Set-GitUserConfig -RepoPath $bareRepoPath -GitUserName $GitUserName -GitUserEmail $GitUserEmail -RepoType "bare repository"
    
    # Check for existing working directory and .git folder
    $workingDirExists = Test-Path -Path $workingRepoPath
    $gitFolderExists = $workingDirExists -and (Test-Path -Path (Join-Path -Path $workingRepoPath -ChildPath ".git"))
    $hasFiles = $false
    
    if ($workingDirExists) {
        # Check if directory has any files
        $hasFiles = (Get-ChildItem -Path $workingRepoPath -Force | Measure-Object).Count -gt 0
    }
    
    # Handle working repository based on options and existing conditions
    if ($Clone) {
        # Create working directory parent if it doesn't exist
        $workingRepoParent = Split-Path -Path $workingRepoPath -Parent
        if (-not (Test-Path -Path $workingRepoParent)) {
            Write-ColorMessage "Creating directory $workingRepoParent" -Type Processing
            New-Item -Path $workingRepoParent -ItemType Directory -Force | Out-Null
        }
        if ($workingDirExists) {
            if ($gitFolderExists) {
                Write-ColorMessage "Working directory at $workingRepoPath already has a .git folder. Skipping clone/init operations." -Type Warning
            }
            elseif ($hasFiles) {
                Write-ColorMessage "Working directory exists with files but no .git folder. Initializing Git instead of cloning." -Type Processing
                Push-Location $workingRepoPath
                try {
                    # Initialize Git repository
                    Write-ColorMessage "Initializing Git repository in existing directory" -Type Processing
                    git init
                    
                    # Set up remote to point to bare repository
                    Write-ColorMessage "Setting up remote 'origin' to point to bare repository" -Type Processing
                    git remote add origin "$bareRepoPath"

                    # Set the default branch name to `main`
                    git checkout -b main
                    
                    # Configure Git user settings for working repository
                    Set-GitUserConfig -RepoPath $workingRepoPath -GitUserName $GitUserName -GitUserEmail $GitUserEmail -RepoType "working repository"
                    
                    # Create initial commit if requested
                    if ($InitialCommit) {
                        Write-ColorMessage "Creating initial commit with existing files" -Type Processing
                        git add .
                        git commit -m "Initial commit"
                        
                        # Push to remote
                        Write-ColorMessage "Pushing initial commit to remote" -Type Processing
                        git push -u origin main
                    }
                }
                finally {
                    Pop-Location
                }
            }
            else {
                # Directory exists but is empty, safe to remove and clone
                Remove-Item -Path $workingRepoPath -Force
                Write-ColorMessage "Cloning repository to $workingRepoPath" -Type Processing
                git clone "$bareRepoPath" "$workingRepoPath"
                
                # Configure Git user settings for working repository
                Set-GitUserConfig -RepoPath $workingRepoPath -GitUserName $GitUserName -GitUserEmail $GitUserEmail -RepoType "working repository"
            }
        }
        else {
            # Standard clone operation
            Write-ColorMessage "Cloning repository to $workingRepoPath" -Type Processing
            git clone "$bareRepoPath" "$workingRepoPath"
            
            # Configure Git user settings for working repository
            Set-GitUserConfig -RepoPath $workingRepoPath -GitUserName $GitUserName -GitUserEmail $GitUserEmail -RepoType "working repository"
        }
    }
    else {
        Write-ColorMessage "Clone not specified. No working repository created." -Type Info
    }
    
    Write-ColorMessage "Repository creation completed successfully." -Type Success
}
