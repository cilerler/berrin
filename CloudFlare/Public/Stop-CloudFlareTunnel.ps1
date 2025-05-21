function Stop-CloudFlareTunnel {
    [CmdletBinding()]
    param()
	
    docker rm -f $(docker ps -q -f ancestor=cloudflare/cloudflared)
}
