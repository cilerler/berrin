# This module doesn't need to do anything - PowerShell will automatically
# load the nested modules specified in the manifest and make their exported
# functions available in the parent module.

Start-Transcript -Path (Join-Path $env:TEMP "$($MyInvocation.MyCommand.Name).log");
# Write-Host "Starting '$($MyInvocation.MyCommand.Name)'";

# Import Shared Helper Module
$SharedModule = Join-Path -Path $PSScriptRoot -ChildPath "SharedCode\SharedHelper.psm1"
Import-Module $SharedModule -Force

# Write-Host "Finishing '$($MyInvocation.MyCommand.Name)'";
Stop-Transcript
