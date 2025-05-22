function Invoke-GitRepositoriesMaintenance() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$branch,
        [Parameter(Mandatory=$false)]
        [switch]$pull,
        [Parameter(Mandatory=$false)]
        [switch]$prune,
        [Parameter(Mandatory=$false)]
        [switch]$compare,
        [Parameter(Mandatory=$false)]
        [switch]$delete,
        [Parameter(Mandatory=$false)]
        [switch]$all
    )
    Push-Location
    if (Test-Path -Path ".git" -PathType Container) {
        Write-Output "Skipping: $((Get-Location).Path) is a Git repository!"
        return
    } else {
        (Get-ChildItem -Directory).FullName | ForEach-Object {
            Write-Output "----- $([System.IO.Path]::GetFileName($_))"
            Set-Location $_
            Invoke-GitRepositoryMaintenance -branch $branch -pull:$pull -prune:$prune -compare:$compare -delete:$delete -all:$all
            Set-Location ..
        }
    }
    Pop-Location
}
