<#
.SYNOPSIS
    Creates timestamped ZIP archives of local files and folders based on configurable path lists.

.DESCRIPTION
    This function reads a list of file and folder paths from a configuration file,
    copies them to a temporary staging directory, and creates a compressed archive.
    The archive filename includes the hostname and timestamp for easy identification.
    Supports environment variable expansion in path specifications and provides
    temporary folder management with optional cleanup.

.PARAMETER BackupRoot
    The root directory for backup operations. Contains the config file, temporary
    staging folder, and the resulting archive. Default is $env:userprofile\Source\local\archives.

.PARAMETER ConfigFileName
    The name of the configuration file containing paths to backup. Must exist in
    BackupRoot directory. Default is '_backup_paths.txt'.

.PARAMETER TempFolderName
    The name of the temporary staging directory used during backup. Created in
    BackupRoot and deleted after archiving (unless -KeepTemp is specified).
    Default is '_temp'.

.PARAMETER KeepTemp
    When specified, prevents deletion of the temporary staging directory after
    successful archive creation. Useful for debugging or manual inspection.

.EXAMPLE
    Backup-Local
    Uses default settings to create a backup archive using paths from
    $env:userprofile\Source\local\archives\_backup_paths.txt

.EXAMPLE
    Backup-Local -ConfigFileName "important-files.txt" -KeepTemp
    Uses a custom config file and preserves the temporary staging directory
    for inspection.

.EXAMPLE
    Backup-Local -BackupRoot "D:\MyBackups" -TempFolderName "staging"
    Uses a custom backup location with a custom temporary folder name.

.EXAMPLE
    Backup-Local -ConfigFileName "daily-backup.txt" -TempFolderName "work"
    Creates a backup using custom configuration and temporary folder names
    while maintaining the default backup root location.

.NOTES
    Configuration file format: One path per line, supports comments (#) and
    environment variables like $env:userprofile
    Ensure the configuration file exists before running. The script will abort
    if no valid paths are found or if no files can be successfully copied.
    Archive naming convention: {hostname}_{yyyyMMddHHmmss}.zip
#>
function Backup-Local {
    [CmdletBinding()]
    param(
        [string]$BackupRoot = "$env:userprofile\Source\local\archives",
        [string]$ConfigFileName = "_backup_paths.txt",
        [string]$TempFolderName = "_temp",
        [switch]$KeepTemp
    )

    # Config file and temp folder are always in BackupRoot
    $configFile = Join-Path -Path $BackupRoot -ChildPath $ConfigFileName
    $backupFolder = Join-Path -Path $BackupRoot -ChildPath $TempFolderName

    # Check if config file exists
    if (-not (Test-Path $configFile)) {
        Write-Host "Config file not found: $configFile" -ForegroundColor Red
        return
    }

    # Read paths from config file
    try {
        $pathsToBackup = Get-Content -Path $configFile -ErrorAction Stop |
        Where-Object { $_ -and $_ -notmatch '^\s*#' } |  # Remove comments and empty lines
        ForEach-Object { $_.Trim() } |                   # Trim whitespace
        Where-Object { $_ } |                           # Remove empty strings
        ForEach-Object {
            # Expand environment variables
            $ExecutionContext.InvokeCommand.ExpandString($_)
        }
    }
    catch {
        Write-Host "Error reading config file: $_" -ForegroundColor Red
        return
    }

    if ($pathsToBackup.Count -eq 0) {
        Write-Host "No valid paths found in config file" -ForegroundColor Yellow
        return
    }

    # Cleanup temp folder if it exists
    if (Test-Path $backupFolder) {
        Write-Host "Removing $backupFolder" -ForegroundColor Cyan
        Remove-Item $backupFolder -Recurse -Force -ErrorAction Stop
    }

    # Ensure archive directory exists
    if (-not (Test-Path $BackupRoot)) {
        New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null
    }

    Write-Host "==== BACKUP OPERATION START ==== $(Get-Date)" -ForegroundColor Magenta
    Write-Host "Processing $($pathsToBackup.Count) paths from config file..." -ForegroundColor Cyan

    $successCount = 0

    # Process all paths (files and folders) in a single pass
    foreach ($source in $pathsToBackup) {
        if (Test-Path $source) {
            # Determine if source is a file or directory
            $isDirectory = (Get-Item $source) -is [System.IO.DirectoryInfo]
            # Only FILES go into the temp folder for the main ZIP
            # Directories are handled by Backup-Content
            if ($isDirectory) {
                Write-Host "Backing up directory: $source" -ForegroundColor Cyan
                try {
                    Backup-Content -SourcePath $source -RootFolder $BackupRoot
                    $successCount++
                }
                catch {
                    Write-Warning "Failed to backup directory $source : $_"
                }
            }
            else {
                # Files go into the temp folder
                $relativePath = $source.Replace("$env:userprofile\", "")
                $destination = Join-Path -Path "$backupFolder\$env:username" -ChildPath $relativePath

                # Create destination directory
                $destDir = Split-Path -Path $destination -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                }

                try {
                    Write-Host "Backing up file: $source" -ForegroundColor Cyan
                    Copy-Item -Path $source -Destination $destination -ErrorAction Stop
                    $successCount++
                }
                catch {
                    Write-Warning "Failed to copy $source : $_"
                }
            }
        }
        else {
            Write-Warning "Source item not found: $source"
        }
    }

    # Check if any files were successfully copied
    if ($successCount -eq 0) {
        Write-Host "No files were successfully copied. Aborting archive creation." -ForegroundColor Yellow
        return
    }

    # Only create the main ZIP if there's content in the temp folder
    if ((Test-Path $backupFolder) -and (Test-Path "$backupFolder\*")) {
        try {
            Write-Host "Creating archive for collected files" -ForegroundColor Cyan
            Backup-Content -SourcePath $backupFolder -RootFolder $BackupRoot
        } catch {
            Write-Host "Failed to create archive: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "No files to archive in main ZIP" -ForegroundColor Yellow
    }

    # Summary
    Write-Host "==== BACKUP OPERATION COMPLETE ==== $(Get-Date)" -ForegroundColor Magenta
    Write-Host "Successfully backed up $successCount items" -ForegroundColor Green

    # Cleanup
    if (-not $KeepTemp -and (Test-Path $backupFolder)) {
        Write-Host "Cleaning up temporary files" -ForegroundColor Cyan
        Remove-Item $backupFolder -Recurse -Force
    }
}
