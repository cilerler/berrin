@{
    RootModule = 'Kubernetes.psm1'
    ModuleVersion = '1.0.0'
    GUID = '00000000-0000-0000-0000-000000000001'
    Author = 'Cengiz Ilerler'
    Description = ''
    FunctionsToExport = @('Enter-K8SContainer','Update-K8sSecrets','Update-K8sConfigMap')
}