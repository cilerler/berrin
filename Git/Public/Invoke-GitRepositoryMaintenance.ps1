<#
.SYNOPSIS
    Performs maintenance operations (update, prune, compare, or delete branches) on one or more Git repositories.

.DESCRIPTION
    Invoke-GitRepositoryMaintenance operates on the current directory if it is a Git repository, performing operations such as:
    - Pulling or fetching all branches
    - Pruning and optionally deleting local branches that have been removed from the remote
    - Comparing local and remote branches
    - Updating all branches in a repository

    Invoke-GitRepositoriesMaintenance iterates through each immediate subdirectory, assuming each is a Git repository, and performs the same operations in batch. This is designed for batch maintenance of multiple repositories in a parent folder, or for a single repository if run inside it.

.PARAMETER branch
    The branch to operate on. Defaults to the current branch if not specified.

.PARAMETER pull
    If specified, performs a git pull (or fetch if not specified) for the selected branch(es).

.PARAMETER prune
    If specified, prunes local branches that no longer exist on the remote. Can be combined with -delete to remove them.

.PARAMETER compare
    If specified, compares the selected branch with the remote HEAD and outputs the difference summary.

.PARAMETER delete
    If specified with -prune, deletes local branches that have been removed from the remote.

.PARAMETER all
    If specified with -pull, updates all local branches in each repository.

.EXAMPLE
    # Pull and prune branches in the current repository only (run from inside a single repository)
    Invoke-GitRepositoryMaintenance -pull -prune
    # Pulls and prunes branches in the current repository only.

.EXAMPLE
    # Run from a parent directory containing multiple repositories
    Invoke-GitRepositoriesMaintenance -pull
    # Pulls the current branch in all subfolder repositories.

.EXAMPLE
    # Prune and delete local branches that have been removed from the remote in the current repository
    Invoke-GitRepositoryMaintenance -prune -delete

.EXAMPLE
    # Compare the local 'develop' branch with the remote HEAD in the current repository
    Invoke-GitRepositoryMaintenance -compare -branch develop

.EXAMPLE
    # Pull all local branches in the current repository
    Invoke-GitRepositoryMaintenance -pull -all

.EXAMPLE
    # Fetch all branches in the current repository without pulling
    Invoke-GitRepositoryMaintenance

.EXAMPLE
    # Prune only (do not delete) local branches that are gone from remote in the current repository
    Invoke-GitRepositoryMaintenance -prune

.EXAMPLE
    # Compare the current branch with the remote HEAD in the current repository
    Invoke-GitRepositoryMaintenance -compare

.EXAMPLE
    # Pull all branches and prune deleted branches in the current repository
    Invoke-GitRepositoryMaintenance -pull -all -prune

.EXAMPLE
    # Fetch and compare a specific branch in the current repository
    Invoke-GitRepositoryMaintenance -compare -branch feature/xyz

.NOTES
    Requires Git to be installed and available in the system PATH.
    Run Invoke-GitRepositoryMaintenance from inside a single repository, or Invoke-GitRepositoriesMaintenance from the parent directory containing your repositories.
#>

function Invoke-GitRepositoryMaintenance {
    param(
        [string]$branch,
        [switch]$pull,
        [switch]$prune,
        [switch]$compare,
        [switch]$delete,
        [switch]$all
    )
    if (-not (Test-Path -Path ".git" -PathType Container)) {
        Write-Output "Skipping: $((Get-Location).Path) is not a Git repository."
        return
    }
    $activeBranch = $(git rev-parse --abbrev-ref HEAD)
    if ([string]::IsNullOrWhiteSpace($branch)) {
        $updatedBranch = $activeBranch
    } else {
        $updatedBranch = $branch
    }
    if ($prune) {
        if ($pull) {
            git pull --all --prune
        }
        else {
            git fetch --all --prune
        }
        git branch -v | Select-String -Pattern '^  (?<branchName>\S+)\s+\w+ \[gone\]' | ForEach-Object {
            if ($delete -eq $true) {
                git branch -D $_.Matches[0].Groups['branchName']
            }
            else {
                Write-Output $_
            }
        }
    }
    else {
        if ($pull) {
            if ($all.IsPresent) {
                if (git status --porcelain) {
                    Write-Output "There are uncommitted changes in the repository. Aborting script."
                }
                else {
                    $branches = git branch | ForEach-Object { $_.TrimStart('*').Trim() }
                    foreach ($branchToUpdate in $branches) {
                        Write-Output "Checking out branch [$branchToUpdate]"
                        git checkout $branchToUpdate
                        git pull --all
                    }
                    git checkout $activeBranch
                }
            }
            else {
                git pull --all
            }
        }
        else {
            git fetch --all
        }
    }
    if ($compare) {
        git branch -r
        $remoteHead = $(git symbolic-ref --short -q 'refs/remotes/origin/HEAD')
        $errOutput = $( $output = & git diff --numstat "refs/remotes/origin/$updatedBranch" "refs/remotes/$remoteHead" ) 2>&1
        if (!$?) {
            $err = ($errOutput[0] | out-string).Trim()
            if ($err.StartsWith("fatal: ambiguous argument") -or $err.StartsWith("error: Could not access 'refs/remotes/origin/$updatedBranch'")) {
                Write-Output "'origin/$updatedBranch' branch does not exist in the repository."
            }
            else {
                Write-Output "Unknown error occured while runing diff command: $err"
            }
        }
        elseif ($output) {
            $list = $output.Split([System.Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries)
            Write-Output "$($list.length) files are different between 'origin/$updatedBranch' and '$remoteHead'"
        }
        else {
            Write-Output "There are no files that are different between 'origin/$updatedBranch' and '$remoteHead'"
        }
    }
    else {
        git branch -a
    }
}
