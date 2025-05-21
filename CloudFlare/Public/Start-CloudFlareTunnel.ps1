function Start-CloudFlareTunnel {
    [CmdletBinding()]
    param(
		[Parameter(Mandatory = $true)]
        [string]$Token
	)

	#TODO: This should be retrieved from PowerShell Vault
    docker run -d cloudflare/cloudflared:latest tunnel --no-autoupdate run --token $token
}
