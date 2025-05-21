<#
.SYNOPSIS
    Restores content from either a Git bundle or a ZIP archive.

.DESCRIPTION
    Restore-Content extracts content from a backup file (either Git bundle or ZIP archive)
    to a specified target location. It supports restoring the latest backup file based on
    timestamp in the filename.

.PARAMETER BackupFile
    Path to the backup file (Git bundle or ZIP archive) to restore.
    If a file without timestamp is provided (e.g., "MyFile.zip"), the function will
    search for the latest timestamped version (e.g., "MyFile.20250512123045.zip").
    If a file with timestamp is provided, that exact file will be used.

.PARAMETER ArchiveFolder
    Path where archives are stored. Defaults to "$env:USERPROFILE\Source\local\archives".
    Used when the provided BackupFile is not an absolute path or not found at the specified location.

.PARAMETER TargetPath
    Path where the content should be restored to.

.PARAMETER ExcludePatterns
    Specifies patterns to exclude from the restored content. Can be used in several ways:
    - When used as a switch or not specified: Excludes common source control files/folders (.git, .svn, etc.) - This is the default behavior
    - When provided with file/folder patterns: Uses only the specified patterns
    - When provided with a hashtable with UseDefaults=$true: Uses default patterns plus custom ones
    - When $null or $false: No exclusions applied

    Examples:
    -ExcludePatterns                                               # Uses default exclusions for source control
    -ExcludePatterns ".git", "bin", "obj"                          # Uses only these specific exclusions
    -ExcludePatterns @{UseDefaults=$true; Custom=@("*.log","bin")} # Uses defaults plus custom patterns
    -ExcludePatterns:$false                                        # No exclusions
    -ExcludePatterns $null                                         # No exclusions (alternative)

.PARAMETER Force
    When specified, allows restoring a timestampless backup file to a specific target path without confirmation.
    Use this to override the safety check that prevents accidental overwrites.

.EXAMPLE
    Restore-Content -BackupFile "C:\Backups\my-project.20250510123045.bundle" -TargetPath "C:\Projects\Restored"
    Restores the specified Git bundle to the target path with default source control exclusions applied.

.EXAMPLE
    Restore-Content -BackupFile "my-website.zip" -TargetPath "C:\Projects\Restored" -ExcludePatterns
    Finds and restores the latest backup of "my-website" excluding common source control folders/files.

.EXAMPLE
    Restore-Content -BackupFile "my-project.zip" -TargetPath "C:\Projects\Restored" -ExcludePatterns ".git", "bin", "obj", "node_modules", "*.ignore"
    Restores the latest backup, excluding only the specified patterns and not the default source control folders.

.EXAMPLE
    Restore-Content -BackupFile "my-app.zip" -TargetPath "C:\Projects\Restored" -ExcludePatterns @{UseDefaults=$true; Custom=@("bin","obj","*.tmp")}
    Restores the latest backup, excluding both default source control patterns AND the custom patterns provided.

.EXAMPLE
    Restore-Content -BackupFile "repository.bundle" -TargetPath "D:\Projects\MyRepo"
    Restores from a Git bundle named "repository" (latest timestamped version) to the specified target path.
    Since the file path is not absolute, the function automatically searches in the default archive location
    ($env:USERPROFILE\Source\local\archives) for the bundle file or its latest timestamped version.
    Since ExcludePatterns is not explicitly specified, it defaults to $true, meaning all common source control
    files and folders (like .git, .svn, etc.) will be excluded from the restored content. This behavior ensures
    that the restored repository is clean from source control metadata that might conflict with new settings.

.INPUTS
    None. Does not accept pipeline input.

.OUTPUTS
    None. Writes status messages and errors to the host.

.NOTES
    Requires Git be installed and on the PATH for Git bundle restoration.
    For ZIP archives, requires PowerShell 5.0+ for Expand-Archive cmdlet.
#>
function Restore-Content {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupFile,
        
        [Parameter(Mandatory=$false)]
        [string]$ArchiveFolder = "$env:USERPROFILE\Source\local\archives",
        
		[Parameter(Mandatory=$true)]
        [string]$TargetPath,
        
		[Parameter(Mandatory=$false)]
        [Alias("ExcludeSourceControl")]
        [object]$ExcludePatterns = $true,
        
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )
    $ErrorActionPreference = 'Stop'
    
    # Variable to track if we're using a timestampless backup file
    $usingTimestamplessFile = $false
    
    # Check if the file exists at the exact provided path first
    if (Test-Path -Path $BackupFile) {
        Write-Host "Using specified backup file: $BackupFile" -ForegroundColor Cyan
    }
    else {
        # Check if the path is absolute or not
        $isAbsolutePath = [System.IO.Path]::IsPathRooted($BackupFile)
        
        if (-not $isAbsolutePath) {
            # If not absolute, try looking in the archive folder
            $archiveFolderFilePath = Join-Path -Path $ArchiveFolder -ChildPath $BackupFile
            
            if (Test-Path -Path $archiveFolderFilePath) {
                # Found the exact file in the archive folder
                $BackupFile = $archiveFolderFilePath
                Write-Host "Found backup file in archive folder: $BackupFile" -ForegroundColor Cyan
            }
            else {
                # Check if it's a base name (without timestamp) to find the latest timestamped version
                $fileInfo = [System.IO.FileInfo]$BackupFile
                $fileNameWithoutExtension = $fileInfo.BaseName
                $extension = $fileInfo.Extension
                
                # Check if the filename already contains a timestamp pattern
                if ($fileNameWithoutExtension -match "\d{14}$") {
                    # File has a timestamp but doesn't exist
                    throw "Backup file not found: $BackupFile or $archiveFolderFilePath"
                }
                
                # Mark that we're using a timestampless file
                $usingTimestamplessFile = $true
                
                # Look for timestamped versions in the ArchiveFolder
                $searchPattern = "$fileNameWithoutExtension.*$extension"
                $matchingFiles = Get-ChildItem -Path $ArchiveFolder -Filter $searchPattern | Sort-Object LastWriteTime -Descending
                
                if ($matchingFiles.Count -eq 0) {
                    throw "No backup files found matching the pattern: $searchPattern in $ArchiveFolder"
                }
                
                # Use the most recent matching file
                $BackupFile = $matchingFiles[0].FullName
                Write-Host "Using latest backup file: $BackupFile" -ForegroundColor Cyan
            }
        }
        else {
            # It's an absolute path but file doesn't exist
            throw "Backup file does not exist: $BackupFile"
        }
    }
    
    # Safety check for timestampless file with target path
    if ($usingTimestamplessFile -and -not $Force) {
        Write-Warning "You are trying to restore a timestampless backup file to a specific target path."
        Write-Warning "This could potentially overwrite files unintentionally."
        Write-Warning "To proceed, either:"
        Write-Warning "  1. Re-run the command without the TargetPath parameter, or"
        Write-Warning "  2. Add the -Force parameter to override this safety check"
        throw "Operation aborted for safety. Use -Force to override."
    }
    
    # Determine file type (bundle or zip) based on extension
    $fileExtension = [System.IO.Path]::GetExtension($BackupFile).ToLower()
    $isBundle = $fileExtension -eq ".bundle"
    
    # Create temp directory for extraction
    $tempPath = Join-Path -Path (Split-Path -Path $BackupFile -Parent) -ChildPath "_temp"
    if (Test-Path -Path $tempPath) {
        Remove-Item -Path $tempPath -Recurse -Force
    }
    New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
    
    # Extract content based on file type
    if ($isBundle) {
        # Git bundle extraction
        Write-Host "Extracting Git bundle to temporary location: $tempPath"
        
        # Clone from bundle to temp directory
        git clone $BackupFile $tempPath
        if ($LASTEXITCODE -ne 0) {
            throw "Git clone from bundle failed with exit code $LASTEXITCODE"
        }
    }
    else {
        # ZIP archive extraction
        Write-Host "Extracting ZIP archive to temporary location: $tempPath"
        Expand-Archive -Path $BackupFile -DestinationPath $tempPath -Force
    }
    
    # Create target directory if it doesn't exist
    if (-not (Test-Path -Path $TargetPath)) {
        Write-Host "Creating target directory at $TargetPath"
        New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
    }    # Prepare robocopy arguments
    $robocopyArgs = @($tempPath, $TargetPath, "/MIR", "/NJH", "/NJS", "/NP", "/NFL", "/NDL")
      # Handle exclusion patterns
    if ($PSBoundParameters.ContainsKey('ExcludePatterns')) {
        # Define default exclusion patterns for source control
        $defaultDirectories = @(
			".git",      # Git
			".svn",      # Subversion
			".hg",       # Mercurial
			".bzr",      # Bazaar
			"_darcs",    # Darcs
			".pijul",    # Pijul
			".fossil",   # Fossil
			"CVS",       # CVS
			"RCS",       # RCS
			"SCCS",      # SCCS
			".repo",     # Google Repo (wrapper around Git)
			".arch-ids", # GNU arch
			".monotone", # Monotone
			".svk",      # SVK (built on top of Subversion)
			".bk"        # BitKeeper
    	)
        $defaultFiles = @(
			# Git
			".gitignore", 
			".gitattributes", 
			".gitmodules", 
			".git-credentials",
			
			# Subversion
			".svnignore",
			
			# Mercurial
			".hgignore", 
			".hgsub", 
			".hgsubstate", 
			".hgtags",
			
			# Bazaar
			".bzrignore",
			
			# Darcs / Pijul / Fossil
			# (Darcs and Pijul live entirely in their dirs; Fossil also has a settings file)
			".fossil-settings",
			
			# CVS
			".cvsignore",
			
			# Perforce
			".p4ignore",
			
			# Team Foundation / TFS
			".tfignore", 
			"vssver.scc", 
			"vssver2.scc", 
			"mssccprj.scc"
		)
        
        # Determine how to handle the ExcludePatterns parameter
        if ($ExcludePatterns -is [System.Management.Automation.SwitchParameter] -or $ExcludePatterns -eq $true) {
            # Use default exclusions - parameter used as a switch or $true
            $directoriesToExclude = $defaultDirectories
            $filesToExclude = $defaultFiles
            Write-Host "Using default source control exclusions" -ForegroundColor Yellow
        }
        elseif ($ExcludePatterns -is [Hashtable]) {
            # Check if we should use defaults plus custom patterns
            if ($ExcludePatterns.ContainsKey('UseDefaults') -and $ExcludePatterns['UseDefaults'] -eq $true) {
                # Start with default exclusions
                $directoriesToExclude = [System.Collections.ArrayList]@($defaultDirectories)
                $filesToExclude = [System.Collections.ArrayList]@($defaultFiles)
                
                # Add custom patterns if provided
                if ($ExcludePatterns.ContainsKey('Custom') -and $ExcludePatterns['Custom'] -is [Array]) {
                    foreach ($pattern in $ExcludePatterns['Custom']) {
                        if ($pattern.StartsWith('*') -or $pattern.Contains('.')) {
                            # Likely a file pattern
                            [void]$filesToExclude.Add($pattern)
                        }
                        else {
                            # Likely a directory pattern
                            [void]$directoriesToExclude.Add($pattern)
                        }
                    }
                }
                Write-Host "Using default source control exclusions plus custom patterns" -ForegroundColor Yellow
            }
            else {
                # Handle as regular custom patterns
                $customPatterns = @($ExcludePatterns.Values)
                $directoriesToExclude = @()
                $filesToExclude = @()
                
                foreach ($pattern in $customPatterns) {
                    if ($pattern.StartsWith('*') -or $pattern.Contains('.')) {
                        # Likely a file pattern
                        $filesToExclude += $pattern
                    }
                    else {
                        # Likely a directory pattern
                        $directoriesToExclude += $pattern
                    }
                }
                Write-Host "Using custom exclusion patterns from hashtable" -ForegroundColor Yellow
            }
        }
        elseif ($ExcludePatterns -is [Array] -or $ExcludePatterns -is [string]) {
            # User provided custom patterns
            $customPatterns = @($ExcludePatterns)  # Force array
            
            # Separate directory and file patterns
            $directoriesToExclude = @()
            $filesToExclude = @()
            
            foreach ($pattern in $customPatterns) {
                if ($pattern.StartsWith('*') -or $pattern.Contains('.')) {
                    # Likely a file pattern
                    $filesToExclude += $pattern
                }
                else {
                    # Likely a directory pattern
                    $directoriesToExclude += $pattern
                }
            }
            
            Write-Host "Using custom exclusion patterns" -ForegroundColor Yellow
        }
        elseif ($null -eq $ExcludePatterns -or $ExcludePatterns -eq $false) {
            # No exclusions
            $directoriesToExclude = @()
            $filesToExclude = @()
            Write-Host "No exclusion patterns applied" -ForegroundColor Yellow
        }
        
        # Add directory exclusions
        foreach ($dir in $directoriesToExclude) {
            if (-not [string]::IsNullOrWhiteSpace($dir)) {
                $robocopyArgs += "/XD"
                $robocopyArgs += $dir
            }
        }
        
        # Add file exclusions
        foreach ($file in $filesToExclude) {
            if (-not [string]::IsNullOrWhiteSpace($file)) {
                $robocopyArgs += "/XF"
                $robocopyArgs += $file
            }
        }
    }
    
    # Copy files to target path with appropriate exclusions
    Write-Host "Copying files to $TargetPath"
    robocopy @robocopyArgs
    
    # Clean up temp directory
    Write-Host "Cleaning up temporary directory"
    Remove-Item -Path $tempPath -Recurse -Force
    
    Write-Host "Restore completed successfully." -ForegroundColor Green
}
