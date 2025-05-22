function Initialize-DesktopEnvironmentPowerShellCore {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BasePath,

        [Parameter()]
        [string]$TerminalBackgroundImagePath
    )

    Write-Verbose "Continuing desktop environment initialization..."
    try {
        Write-Verbose "Installling Terminal"
        Install-Terminal -BasePath "$BasePath" -TerminalBackgroundImagePath "$TerminalBackgroundImagePath"

        Write-Verbose "Installling OhMyPosh"
        Install-OhMyPosh -BasePath "$BasePath"
        Initialize-OhMyPosh
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red;
        Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow;
        Write-Host "Error Details:" -ForegroundColor Cyan;
        Write-Host "  Message: $($_.Exception.Message)";
        Write-Host "  Type: $($_.Exception.GetType().FullName)";
        Write-Host "  Line: $($_.InvocationInfo.ScriptLineNumber)";
        Write-Host "  Column: $($_.InvocationInfo.OffsetInLine)";
        Write-Host "  Script: $($_.InvocationInfo.ScriptName)";
    }

    Write-Verbose "Second part of desktop environment initialization complete."
}
