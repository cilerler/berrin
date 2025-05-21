<#
.SYNOPSIS
    Sets Git user configuration for multiple Git repositories in a folder.

.DESCRIPTION
    Set-GitUserConfigBulk configures Git user.name and user.email for all Git repositories
    found in the root level of the specified folder. It identifies repositories by checking
    for the presence of a .git folder in each directory. You can exclude specific folders
    from the operation by providing their names.

.PARAMETER FolderPath
    The path to the folder containing Git repositories to configure.
    Each direct subfolder will be checked for a .git directory.

.PARAMETER ExcludeFolders
    An array of folder names to exclude from configuration.
    Matches folder names exactly, including spaces.

.PARAMETER GitUserName
    Value for user.name in the Git configuration.

.PARAMETER GitUserEmail
    Value for user.email in the Git configuration.

.PARAMETER DryRun
    When specified, lists the repositories that would be configured without making any changes.

.EXAMPLE
    Set-GitUserConfigBulk -FolderPath "C:\Projects" -GitUserName "John Doe" -GitUserEmail "john.doe@example.com"
    Sets Git user configuration for all repositories under C:\Projects.

.EXAMPLE
    Set-GitUserConfigBulk -FolderPath "C:\Projects" -ExcludeFolders "Personal Project","External Source" -GitUserName "John Doe" -GitUserEmail "john.doe@example.com"
    Sets Git user configuration for all repositories except the specified folders.

.EXAMPLE
    Set-GitUserConfigBulk -FolderPath "C:\Projects" -GitUserName "John Doe" -GitUserEmail "john.doe@example.com" -DryRun
    Lists the repositories that would be configured without making any changes.

.INPUTS
    None. Does not accept pipeline input.

.OUTPUTS
    None. Writes status messages to the host.

.NOTES
    Requires Git be installed and on the PATH.
#>
function Set-GitUserConfigBulk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FolderPath,
        
        [Parameter(Mandatory=$false)]
        [string[]]$ExcludeFolders = @(),
        
        [Parameter(Mandatory=$false)]
        [string]$GitUserName,
        
        [Parameter(Mandatory=$false)]
        [string]$GitUserEmail,
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    $ErrorActionPreference = 'Stop'
      # Validate parameters
    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        throw "The specified folder path '$FolderPath' does not exist or is not a directory."
    }
    
    if (-not ($GitUserName -or $GitUserEmail)) {
        throw "At least one of GitUserName or GitUserEmail must be specified."
    }
    
    # Get all directories in the specified folder (non-recursive)
    $allFolders = Get-ChildItem -Path $FolderPath -Directory
      # Initialize counters for logging
    $processedCount = 0
    $excludedCount = 0
    $repositoryCount = 0
    $repoList = @()
    $nonGitFolderList = @()
    
    if ($DryRun) {
        Write-Host "DRY RUN MODE: No changes will be made" -ForegroundColor Yellow
    }
    
    Write-Host "==== OPERATION START ==== $(Get-Date)" -ForegroundColor Magenta
    Write-Host "Searching for Git repositories in $FolderPath..." -ForegroundColor Cyan
    
    # Process each folder
    foreach ($folder in $allFolders) {
        $folderName = $folder.Name
        $folderPath = $folder.FullName
          # Check if the folder should be excluded
        if ($ExcludeFolders -contains $folderName) {
            if ($DryRun) {
                Write-Host "Would skip excluded folder: $folderName" -ForegroundColor Yellow
            } else {
                Write-Host "Skipping excluded folder: $folderName" -ForegroundColor Yellow
            }
            $excludedCount++
            continue
        }
        
        # Check if the folder contains a .git directory
        $gitDirPath = Join-Path -Path $folderPath -ChildPath ".git"
        
        if (Test-Path -Path $gitDirPath -PathType Container) {
            if ($DryRun) {
                Write-Host "Would configure Git repository in: $folderName" -ForegroundColor Cyan
                if ($GitUserName) {
                    Write-Host "  Would set user.name to: $GitUserName" -ForegroundColor Cyan
                }
                if ($GitUserEmail) {
                    Write-Host "  Would set user.email to: $GitUserEmail" -ForegroundColor Cyan
                }
                $repoList += $folderPath
            } else {
                Write-Host "Found Git repository in: $folderName" -ForegroundColor Green
                
                # Apply Git user configuration
                Set-GitUserConfig -RepoPath $folderPath -GitUserName $GitUserName -GitUserEmail $GitUserEmail
            }
              $repositoryCount++        
            } else {
            if ($DryRun) {
                Write-Host "Folder '$folderName' is not a Git repository. Would skip." -ForegroundColor Orange
                $nonGitFolderList += $folderPath
            } else {
                Write-Host "Folder '$folderName' is not a Git repository. Skipping." -ForegroundColor Orange
            }
        }
        
        $processedCount++
    }
      # Summary
    Write-Host "==== OPERATION SUMMARY ==== $(Get-Date)" -ForegroundColor Magenta
    Write-Host "Operation completed." -ForegroundColor Green
    Write-Host "Total folders processed: $processedCount" -ForegroundColor Cyan
    Write-Host "Folders excluded: $excludedCount" -ForegroundColor Cyan
      if ($DryRun) {
        Write-Host "Git repositories that would be configured: $repositoryCount" -ForegroundColor Cyan
        if ($repoList.Count -gt 0) {
            Write-Host "Repositories that would be affected:" -ForegroundColor Cyan
            $repoList | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
        }
        if ($ExcludeFolders.Count -gt 0) {
            Write-Host "Folders that would be excluded:" -ForegroundColor Yellow
            $ExcludeFolders | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        }
        if ($nonGitFolderList.Count -gt 0) {
            Write-Host "Folders that would be skipped (not Git repositories): $($nonGitFolderList.Count)" -ForegroundColor Gray
            $nonGitFolderList | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        }
    } else {
        Write-Host "Git repositories configured: $repositoryCount" -ForegroundColor Green
    }
}