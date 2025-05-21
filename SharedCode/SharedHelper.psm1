function Write-ColorMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [string]$Message,
        
        [Parameter(Position = 1)]
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Debug', 'Highlight', 'Processing')]
        [string]$Type = 'Info',
        
        [Parameter()]
        [switch]$NoNewLine,
        
        [Parameter()]
        [switch]$Force
    )
    
    # Define color mappings
    $colorMap = @{
        'Info'       = 'White'
        'Success'    = 'Green'
        'Warning'    = 'Yellow'
        'Error'      = 'Red'
        'Debug'      = 'Gray'
        'Highlight'  = 'Magenta'
        'Processing' = 'Cyan'
    }
    
    # Add prefix based on message type
    $prefixMap = @{
        'Info'       = '[INFO] '
        'Success'    = '[SUCCESS] '
        'Warning'    = '[WARNING] '
        'Error'      = '[ERROR] '
        'Debug'      = '[DEBUG] '
        'Highlight'  = '[***] '
        'Processing' = '[PROCESSING] '
    }
    
    $prefix = $prefixMap[$Type]
    $color = $colorMap[$Type]
    
    # Get caller's verbose preference - this captures whether the caller used -Verbose
    $callerVerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
    
    # Check if we're being called by the AllModules module
    $callStack = Get-PSCallStack
    $isCalledByAllModules = $callStack | Where-Object { $_.Command -like "*\AllModules.psm1" -or $_.Command -eq "AllModules.psm1" }
    
    # Determine whether to show the message
    $showMessage = $false
    
    # Always show errors regardless of verbose setting
    if ($Type -eq 'Error') {
        $showMessage = $true
    }
    # If called by AllModules, respect verbose preference
    elseif ($isCalledByAllModules) {
        if ($Force -or $callerVerbosePreference -eq 'Continue') {
            $showMessage = $true
        }
    }
    # For direct module calls, always show messages
    else {
        $showMessage = $true
    }
    
    # Display the message if conditions are met
    if ($showMessage) {
        Write-Host "$prefix$Message" -ForegroundColor $color -NoNewline:$NoNewLine
    }
}

Export-ModuleMember -Function Write-ColorMessage