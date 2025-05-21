@{
    RootModule = 'LocalBackup.psm1'
    ModuleVersion = '1.0.0'
    GUID = '00000000-0000-0000-0000-000000000001'
    Author = 'Cengiz Ilerler'
    Description = 'Creates timestamped archives of local files and folders using configurable path lists. Supports environment variable expansion in config files and includes temp folder management.'
    FunctionsToExport = @('Backup-Local','Export-VSCodeExtensions')
}