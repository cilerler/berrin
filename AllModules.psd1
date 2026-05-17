@{
    # Basic module information
    RootModule = 'AllModules.psm1'                                      # Main module file
    ModuleVersion = '1.0.0'                                             # Version using SemVer format
    GUID = '12345678-1234-1234-1234-123456789012'                       # Unique module identifier
    Author = 'Cengiz Ilerler'                                           # Module author
    CompanyName = 'OneDeveloperWay'                                     # Company name (optional)
    Copyright = '(c) 2025 OneDeveloperWay, Inc. All rights reserved.'   # Copyright notice
    Description = 'Master module that loads all other modules'          # Module description

    # PowerShell version requirements
    # PowerShellVersion = '5.1'                                         # Minimum PowerShell version
    # PowerShellHostName = ''                                           # Required host name (if any)
    # PowerShellHostVersion = ''                                        # Required host version (if any)
    # DotNetFrameworkVersion = '4.5'                                    # Minimum .NET Framework version
    # ClrVersion = '4.0'                                                # Minimum CLR version
    # ProcessorArchitecture = 'None'                                    # Required processor architecture

    # Dependencies
    # RequiredModules = @(                                              # Modules required by this module
    #     @{ModuleName='PSReadLine'; ModuleVersion='2.1.0'},
    #     'Az.Storage'
    # )
    # RequiredAssemblies = @()                                          # Required assemblies
    # ScriptsToProcess = @()                                            # Scripts to run when importing
    # TypesToProcess = @()                                              # Type files to process
    # FormatsToProcess = @()                                            # Format files to process        # Nested modules and exports
    NestedModules = @(                                                  # Modules to import
        , 'EnvFx\EnvFx.psd1'
        , 'CloudFlare\CloudFlare.psd1'
        , 'EnvFx\EnvFx.psd1'
        , 'EnvSetup\EnvSetup.psd1'
        , 'Git\Git.psd1'
        , 'Kubernetes\Kubernetes.psd1'
        , 'LocalBackup\LocalBackup.psd1'
        , 'RabbitMQ\RabbitMQ.psd1'
    )
    # FunctionsToExport = @(                                              # Functions to export
    #       'Get-HostFile'
    #     , 'Remove-History'
    #     , 'Set-Local'
    # )
    # CmdletsToExport = @()                                             # Cmdlets to export
    # VariablesToExport = @()                                           # Variables to export
    # AliasesToExport = @('gs', 'ss', 'ns')                             # Aliases to export
    # DscResourcesToExport = @()                                        # DSC resources to export

    # # Private data used by the PowerShell Gallery
    # PrivateData = @{
    #     PSData = @{
    #         # Tags for module discovery in galleries
    #         Tags = @('Utility', 'Management', 'DevOps', 'Azure')

    #         # Project website URL
    #         ProjectUri = 'https://github.com/cilerler/berrin'

    #         # License URL
    #         LicenseUri = 'https://github.com/cilerler/berrin/blob/main/LICENSE'

    #         # Icon URL for the module
    #         IconUri = 'https://raw.githubusercontent.com/cilerler/berrin/main/icon.png'

    #         # Release notes
    #         ReleaseNotes = 'Version 1.2.3: Added new feature X, fixed bug Y'

    #         # Prerelease string for prerelease versions
    #         Prerelease = ''

    #         # Flag to indicate the module requires explicit user acceptance
    #         RequireLicenseAcceptance = $false

    #         # External module dependencies
    #         ExternalModuleDependencies = @('Az.Accounts')

    #         # List of PowerShell editions this module works on
    #         CompatiblePSEditions = @('Desktop', 'Core')
    #     }

    #     # Additional private data if needed
    #     CustomData = @{
    #         SupportContact = 'support@example.com'
    #         DocumentationLink = 'https://docs.example.com/MyModule'
    #     }
    # }

    # # Help info URL
    # HelpInfoURI = 'https://help.example.com/MyModule'
}
