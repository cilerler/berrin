function Get-IniValue {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]$FilePath,
		
		[Parameter(Mandatory = $true)]
		[string]$Key
	)
	
	if (-not (Test-Path -Path $FilePath)) {
		throw "The specified INI file does not exist: $FilePath"
	}
	
	$content = Get-Content -Path $FilePath -ErrorAction Stop
	$commentPattern = "^\s*[;#]"
	$keyPattern = "^\s*$Key\s*=\s*(.+?)\s*$"
	
	foreach ($line in $content) {
		# Skip empty lines or comment lines (starting with ; or #)
		if ([string]::IsNullOrWhiteSpace($line) -or $line -match $commentPattern) {
			continue
		}
		
		if ($line -match $keyPattern) {
			# Get the value and evaluate any environment variables
			$rawValue = $matches[1]
			$evaluatedValue = $ExecutionContext.InvokeCommand.ExpandString($rawValue)
			return $evaluatedValue
		}
	}
	
	throw "Key '$Key' not found in the INI file: $FilePath"
}