@{
    RootModule = 'Git.psm1'
    ModuleVersion = '1.0.0'
    GUID = '00000000-0000-0000-0000-000000000001'
    Author = 'Cengiz Ilerler'
    Description = 'Git repository management functions'
    FunctionsToExport = @('Backup-Content', 'Invoke-GitRepositoriesMaintenance', 'Invoke-GitRepositoryMaintenance', 'New-BareRepository', 'Reset-GitRepository', 'Restore-Content', 'Set-GitUserConfig', 'Set-GitUserConfigBulk')
}
