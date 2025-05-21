@{
    RootModule = 'Git.psm1'
    ModuleVersion = '1.0.0'
    GUID = '00000000-0000-0000-0000-000000000001'
    Author = 'Cengiz Ilerler'
    Description = 'Git repository management functions'
    FunctionsToExport = @('New-BareRepository', 'Backup-Repository', 'Backup-Content', 'Restore-Content', 'Set-GitUserConfigBulk', 'Reset-GitRepository', 'Invoke-GitRepositoryMaintenance', 'Invoke-GitRepositoriesMaintenance')
}
