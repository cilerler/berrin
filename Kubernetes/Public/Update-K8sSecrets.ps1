function Update-K8sSecrets() {
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

	$baseSecretPath = "$env:AppData\Microsoft\UserSecrets"
	$secretRelativePath = "$secretName\appsettings.Secrets.json\$namespace.$deploymentName.json"
	$secretPath = Join-Path -Path $baseSecretPath -ChildPath $secretRelativePath

	if (!(Test-Path($secretPath))) {
		Write-Error "Secret file not found: $secretPath";
		return;
	}
	kubectl delete secret -n $namespace $deploymentName;
	kubectl create secret generic -n $namespace $deploymentName --from-file=appsettings.Secrets.json=$secretPath;
	if ($restart) {
		kubectl rollout restart -n $namespace deployment/$deploymentName;
	}
}