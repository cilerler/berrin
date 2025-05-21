function Update-K8sConfigMap() {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]$namespace, 
		[Parameter(Mandatory = $true)]
		[string]$deploymentName,
		[Parameter(Mandatory = $true)]
		[string]$configMapName,
		[Parameter(Mandatory = $false)]
		[switch]$restart
	)
	
	$baseSecretPath = "$env:AppData\Microsoft\UserSecrets\"
	$configMapRelativePath = "$configMapName\appsettings.ConfigMap.json\$namespace.$deploymentName.json"
	$configMapPath = Join-Path -Path $baseSecretPath -ChildPath $configMapRelativePath

    if (!(Test-Path($configMapPath))) {
        Write-Error "ConfigMap file not found: $configMapPath";
        return;
    }
    kubectl delete configmap -n $namespace $deploymentName;
    kubectl create configmap -n $namespace $deploymentName --from-file=appsettings.ConfigMap.json=$configMapPath;
    if ($restart) {
        kubectl rollout restart -n $namespace deployment/$deploymentName;
    }
}