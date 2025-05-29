<#
.SYNOPSIS
    Creates a backup of content from either a Git repository or a regular directory.

.DESCRIPTION
    Backup-Content examines the provided path and creates either:
    1. A Git bundle file if the source is a Git repository
    2. A ZIP archive if the source is a regular directory
    Archives are stored in $RootFolder with a timestamp.
    Optionally copies the backup to a secondary location (e.g., USB drive, cloud storage).
    For ZIP archives, exclusion patterns can be specified in a .zipignore file similar to .gitignore.

.PARAMETER SourcePath
    Path of the directory to backup. Can be either a Git repository or a regular directory.
    Defaults to the current directory if not specified.

.PARAMETER RootFolder
    Path where archives are stored. Defaults to "$env:USERPROFILE\Source\local\archives".

.PARAMETER TargetRoot
    Optional secondary location to copy the backup file.

.EXAMPLE
    Backup-Content -SourcePath "C:\Projects\MyRepo"
    Creates a backup (bundle or ZIP) based on the type of content found at the path.

.EXAMPLE
    Backup-Content -SourcePath "C:\Projects\MyWebsite" -TargetRoot "G:\Backups"
    Creates a backup using patterns in .zipignore file (if present) and copies it to G:\Backups.

.INPUTS
    None. Does not accept pipeline input.

.OUTPUTS
    None. Writes status messages and errors to the host.

.NOTES
    Requires Git be installed and on the PATH for Git repository backups.
    For ZIP archives, requires PowerShell 5.0+ for Compress-Archive cmdlet.

.ZIPIGNORE
    Sample .zipignore file:

    # Sample .zipignore file - works similar to .gitignore
    # Lines starting with # are comments

    # Ignore specific extensions
    *.log
    *.tmp
    *.temp

    # Ignore specific directories
    node_modules/
    bin/
    obj/
    .vscode/

    # Negation patterns - include despite matching previous patterns
    !bin/important_file.txt

    # Glob patterns
    **/*.zip
    **/temp/**

    # You can also use simple file/directory names
    README.md
    LICENSE
#>
function Backup-Content {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$SourcePath = (Get-Location).Path,

        [Parameter(Mandatory=$false)]
        [string]$RootFolder = "$env:USERPROFILE\Source\local\archives",

        [Parameter(Mandatory=$false)]
        [string]$TargetRoot
    )

    $ErrorActionPreference = 'Stop'

    # Flag to track whether archive was successfully created
    $archiveCreated = $false

    # Function to parse .zipignore file and return patterns
    function Get-ZipIgnorePatterns {
        param(
            [string]$ZipIgnoreFilePath
        )

        if (-not (Test-Path -Path $ZipIgnoreFilePath)) {
            Write-Verbose "ZipIgnore file not found: $ZipIgnoreFilePath"
            return @()
        }

        Write-Verbose "Using ZipIgnore file: $ZipIgnoreFilePath"
        $patterns = @()
        $content = Get-Content -Path $ZipIgnoreFilePath

        foreach ($line in $content) {
            # Skip empty lines and comments
            if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
                continue
            }

            # Add the pattern
            $patterns += $line.Trim()
        }

        return $patterns
    }

    # Function to check if a file should be excluded based on zipignore patterns
    function Test-ShouldExcludeFile {
        param (
            [Parameter(Mandatory=$true)]
            [System.IO.FileSystemInfo]$FileItem,

            [Parameter(Mandatory=$true)]
            [string]$SourceBasePath,

            [Parameter(Mandatory=$true)]
            [string[]]$Patterns
        )

        # Get relative path from source base path
        $relativePath = $FileItem.FullName.Substring($SourceBasePath.Length).TrimStart('\')
        $relativePath = $relativePath.Replace('\', '/')
        $fileName = $FileItem.Name
        $isDirectory = $FileItem.PSIsContainer

        $exclude = $false
        $include = $false

        foreach ($pattern in $Patterns) {
            # Handle negation patterns (inclusion overrides)
            $isNegation = $pattern.StartsWith('!')
            if ($isNegation) {
                $pattern = $pattern.Substring(1).Trim()
            }

            # Convert gitignore style pattern to PowerShell wildcard
            $wildcardPattern = $pattern

            # Handle directory-specific patterns (ending with /)
            $directoriesOnly = $wildcardPattern.EndsWith('/')
            if ($directoriesOnly) {
                $wildcardPattern = $wildcardPattern.TrimEnd('/')
                if (-not $isDirectory) {
                    continue
                }
            }

            # Replace ** with appropriate wildcard
            $wildcardPattern = $wildcardPattern.Replace('**', '###GLOBSTAR###')

            # Convert simple wildcards
            $wildcardPattern = $wildcardPattern.Replace('*', '*').Replace('?', '?')

            # Convert back special placeholders
            $wildcardPattern = $wildcardPattern.Replace('###GLOBSTAR###', '*')

            # Test against the file path using wildcard matching
            $pathMatches = $relativePath -like $wildcardPattern -or
                         $fileName -like $wildcardPattern

            # Handle pattern with leading directory part
            if (-not $pathMatches -and $wildcardPattern.Contains('/')) {
                $pathMatches = $relativePath -like $wildcardPattern
            }

            if ($pathMatches) {
                if ($isNegation) {
                    $include = $true
                } else {
                    $exclude = $true
                }
            }
        }

        # Negation patterns override exclusion
        return $exclude -and -not $include
    }

    # Validate source path exists
    if (-not (Test-Path -Path $SourcePath)) {
        throw "Source path does not exist: $SourcePath"
    }

    # Create archives directory if it doesn't exist
    if (-not (Test-Path -Path $RootFolder)) {
        Write-Host "Creating archives directory at $RootFolder"
        New-Item -Path $RootFolder -ItemType Directory -Force | Out-Null
    }

    # Generate timestamp for filename
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    # Create filename from path (excluding drive letter and colon)
    $pathWithoutDrive = $SourcePath -replace '^[A-Za-z]:', ''
    $pathWithoutDrive = $pathWithoutDrive.TrimStart('\').TrimEnd('\')
    $sanitizedPath = $pathWithoutDrive.Replace('\', '_')

    # Check if the source is a Git repository (works for both normal and bare repositories)
    $isGitRepo = $false
    Push-Location $SourcePath
    try {
        # Use git rev-parse to safely determine if this is a git repository
        # --git-dir works for both normal and bare repositories
        $gitOutput = git rev-parse --git-dir 2>&1
        $isGitRepo = $LASTEXITCODE -eq 0

        # Log repository type for diagnostics
        if ($isGitRepo) {
            $isBare = git config --get core.bare
            if ($isBare -eq "true") {
                Write-Verbose "Detected a bare Git repository at $SourcePath"
            } else {
                Write-Verbose "Detected a normal Git repository at $SourcePath"
            }
        }
    }
    catch {
        Write-Verbose "Not a Git repository: $($_.Exception.Message)"
        $isGitRepo = $false
    }
    finally {
        Pop-Location
    }

    if ($isGitRepo) {
        # Git repository backup logic
        $backupFileName = "$sanitizedPath.$timestamp.bundle"
        $backupFilePath = Join-Path -Path $RootFolder -ChildPath $backupFileName

        Write-Host "Creating Git bundle from $SourcePath to $backupFilePath"
        Push-Location $SourcePath
        try {
            # Create bundle with all branches and tags
            git bundle create $backupFilePath --all
            if ($LASTEXITCODE -ne 0) {
                throw "Git bundle creation failed with exit code $LASTEXITCODE"
            }

            # Verify the bundle
            git bundle verify $backupFilePath
            if ($LASTEXITCODE -ne 0) {
                throw "Git bundle verification failed with exit code $LASTEXITCODE"
            }
            Write-Host "Git bundle created successfully" -ForegroundColor Green
            $archiveCreated = $true
        }
        finally {
            Pop-Location
        }
    } else {
        # Regular directory backup logic - create ZIP archive
        $backupFileName = "$sanitizedPath.$timestamp.zip"
        $backupFilePath = Join-Path -Path $RootFolder -ChildPath $backupFileName

        Write-Host "Creating ZIP archive from $SourcePath to $backupFilePath"

        # Process exclusions based on zipignore file
        $zipIgnorePatterns = @()

        # Look for .zipignore in source directory
        $zipIgnorePath = Join-Path -Path $SourcePath -ChildPath ".zipignore"
        if (Test-Path -Path $zipIgnorePath) {
            $zipIgnorePatterns = Get-ZipIgnorePatterns -ZipIgnoreFilePath $zipIgnorePath
            Write-Host "Using .zipignore file from source directory"
        }

        # Apply zipignore patterns if available
        if ($zipIgnorePatterns.Count -gt 0) {
            Write-Verbose "Applying $(($zipIgnorePatterns).Count) exclusion patterns from .zipignore"

            # Create a temporary directory for filtered content
            $tempFilteredPath = Join-Path -Path $env:TEMP -ChildPath "backup-content-$(Get-Random)"
            New-Item -Path $tempFilteredPath -ItemType Directory -Force | Out-Null

            try {
                # Add trailing slash to source path if not present
                $sourceBasePath = $SourcePath
                if (-not $sourceBasePath.EndsWith('\')) {
                    $sourceBasePath += '\'
                }

                # Get all items and filter
                $items = Get-ChildItem -Path $SourcePath -Recurse
                $includedItems = $items | Where-Object {
                    -not (Test-ShouldExcludeFile -FileItem $_ -SourceBasePath $sourceBasePath -Patterns $zipIgnorePatterns)
                }

                # Copy filtered items to temp directory preserving structure
                foreach ($item in $includedItems) {
                    $relativePath = $item.FullName.Substring($sourceBasePath.Length)
                    $destPath = Join-Path -Path $tempFilteredPath -ChildPath $relativePath

                    if ($item.PSIsContainer) {
                        New-Item -Path $destPath -ItemType Directory -Force | Out-Null
                    } else {
                        $destDir = Split-Path -Path $destPath -Parent
                        if (-not (Test-Path $destDir)) {
                            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                        }
                        Copy-Item -Path $item.FullName -Destination $destPath -Force
                    }
                }

                # Create archive from temp directory
                if (Test-Path "$tempFilteredPath\*") {
                    Compress-Archive -Path "$tempFilteredPath\*" -DestinationPath $backupFilePath -Force
                    Write-Host "ZIP archive created successfully" -ForegroundColor Green
                    $archiveCreated = $true
                } else {
                    Write-Warning "No items found to archive after applying exclusions"
                }
            }
            finally {
                # Cleanup temp directory
                if (Test-Path $tempFilteredPath) {
                    Remove-Item -Path $tempFilteredPath -Recurse -Force
                }
            }
        } else {
            # No zipignore patterns - compress directory contents
            Compress-Archive -Path "$SourcePath\*" -DestinationPath $backupFilePath -Force
            Write-Host "ZIP archive created successfully" -ForegroundColor Green
            $archiveCreated = $true
        }
    }

    # Copy to target location if specified and a backup was created
    if ($archiveCreated -and -not [string]::IsNullOrWhiteSpace($TargetRoot)) {
        $targetBackupPath = Join-Path -Path $TargetRoot -ChildPath $backupFileName

        # Create target directory if it doesn't exist
        if (-not (Test-Path -Path $TargetRoot)) {
            Write-Host "Creating target directory at $TargetRoot"
            New-Item -Path $TargetRoot -ItemType Directory -Force | Out-Null
        }

        if ($backupFilePath -ieq $targetBackupPath) {
            Write-Warning "Source and destination are identical; skipping copy."
        }
        else {
            Write-Host "Copying backup to $targetBackupPath"
            Copy-Item -Path $backupFilePath -Destination $targetBackupPath -Force
        }
    }

    if ($archiveCreated) {
        Write-Host "Backup completed successfully." -ForegroundColor Green
        return $backupFilePath
    } else {
        Write-Host "Backup operation completed, but no archive was created." -ForegroundColor Yellow
        return $null
    }
}
