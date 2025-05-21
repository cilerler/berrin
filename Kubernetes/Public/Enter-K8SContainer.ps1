function Enter-K8SContainer {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]$namespace, 
		[Parameter(Mandatory = $true)]
		[string]$podName
	)

	kubectl -n $namespace exec -it $podName -- bash;
}
