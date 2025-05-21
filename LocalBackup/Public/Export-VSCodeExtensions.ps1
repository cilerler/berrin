function Export-VSCodeExtensions {
    [CmdletBinding()]
    param(
        [string]$FilePath = "$env:userprofile\Source\local\archives\_paths.ini",
        [string]$Key = "VSCodeExtensions"
    )
    
    try {
        # Get the backup path from the INI file
        $BackupPath = Get-IniValue -FilePath $FilePath -Key $Key
        
        if ([string]::IsNullOrWhiteSpace($BackupPath)) {
            throw "The value for key '$Key' is empty or only whitespace."
        }
        
        # Ensure the directory exists
        $backupDir = Split-Path -Path $BackupPath -Parent
        if (-not (Test-Path -Path $backupDir)) {
            New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
        }
        
        # Export VS Code extensions
        Write-Verbose "Exporting VS Code extensions to: $BackupPath"
        code --list-extensions | ForEach-Object { "code --install-extension $_;" } | Out-File -FilePath $BackupPath -Encoding utf8 -Force
        
        Write-Verbose "VS Code extensions successfully exported to: $BackupPath"
    }
    catch {
        Write-Error "Failed to export VS Code extensions: $_"
    }
}
