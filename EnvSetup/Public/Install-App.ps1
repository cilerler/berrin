function Initialize-Installation {
    param(
        [string]$AppName,
        [string]$BasePath
    )

    Start-Transcript -Path (Join-Path $env:TEMP "$AppName-install.log")
    Write-Host "Starting installation for $AppName"
    Write-Host "BasePath: $BasePath"

    $localCache = Join-Path $BasePath "apps\$AppName"
    $workDir = Join-Path $env:TEMP $AppName

    if (-not (Test-Path $workDir)) {
        New-Item -Path $workDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $localCache)) {
        New-Item -Path $localCache -ItemType Directory -Force | Out-Null
    }

    return @{
        LocalCache = $localCache
        WorkDir    = $workDir
        ExtractPath = Join-Path $workDir "extracted"
        LogFile    = Join-Path $workDir "install.log"
    }
}

function Get-LatestRelease {
    param(
        [string]$GitHubRepo,
        [string]$AssetFilter,
        [string]$DependenciesFilter
    )

    Write-Host "Fetching latest release from $GitHubRepo"
    $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubRepo/releases/latest"

    $asset = $latestRelease.assets | Where-Object { $_.name -like $AssetFilter } | Select-Object -First 1

    $dependencyAsset = $null
    if (-not [string]::IsNullOrEmpty($DependenciesFilter)) {
        $dependencyAsset = $latestRelease.assets | Where-Object { $_.name -like $DependenciesFilter } | Select-Object -First 1
    }

    if (-not $asset) {
        Write-Host "No matching asset found in the latest release" -ForegroundColor Red
        return $null
    }

    Write-Host "Latest release asset: $($asset.name)"

    return @{
        MainAsset       = $asset
        DependencyAsset = $dependencyAsset
    }
}

function Get-Installer {
    param(
        [object]$Asset,
        [string]$LocalCache,
        [string]$WorkDir
    )

    $assetName = $Asset.name
    $cachedInstaller = Join-Path $LocalCache $assetName
    $installer = Join-Path $WorkDir $assetName

    if (-not (Test-Path $cachedInstaller)) {
        Write-Host "Downloading latest release to $installer"
        try {
            Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $installer

            # Cache the installer for future use
            Copy-Item $installer $cachedInstaller -Force
        }
        catch {
            Write-Host "Failed to download installer: $_" -ForegroundColor Red
            return $null
        }
    }
    else {
        Write-Host "Copying installer from cache"
        Copy-Item $cachedInstaller $WorkDir -Force
    }

    if (-not (Test-Path $installer)) {
        Write-Host "Installer not found at $installer" -ForegroundColor Red
        return $null
    }

    return $installer
}

function Install-Application {
    param(
        [string]$InstallerPath,
        [string]$AppName,
        [string]$WorkDir,
        [string]$ExtractPath,
        [string]$WingetId,
        [bool]$UseWingetFallback
    )

    $logFile = Join-Path $WorkDir "install.log"
    $extension = [System.IO.Path]::GetExtension($InstallerPath).ToLower()

    Write-Host "Installing $AppName using $InstallerPath"

    try {
        switch ($extension) {
            ".msi" {
                $msiArgs = "/i `"$InstallerPath`" /L*v `"$logFile`" /quiet /norestart"
                $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru

                if ($process.ExitCode -ne 0) {
                    throw "MSI installation failed with exit code $($process.ExitCode)"
                }
            }
            ".msixbundle" {
                Add-AppxPackage -Path $InstallerPath -ErrorAction Stop
            }
            ".zip" {
                Expand-Archive -Path $InstallerPath -DestinationPath $ExtractPath -Force

                # # Look for an executable or script to run
                # $executable = Get-ChildItem -Path $ExtractPath -Recurse -Include "*.exe", "*.msi", "*.ps1" | Select-Object -First 1

                # if ($executable) {
                #     if ($executable.Extension -eq ".msi") {
                #         $msiArgs = "/i `"$($executable.FullName)`" /L*v `"$logFile`" /quiet /norestart"
                #         $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru

                #         if ($process.ExitCode -ne 0) {
                #             throw "MSI installation from ZIP failed with exit code $($process.ExitCode)"
                #         }
                #     }
                #     elseif ($executable.Extension -eq ".exe") {
                #         # $process = Start-Process -FilePath $executable.FullName -ArgumentList "/S", "/quiet" -Wait -PassThru
                #         $process = Start-Process -FilePath $executable.FullName -Wait -PassThru

                #         if ($process.ExitCode -ne 0) {
                #             throw "EXE installation from ZIP failed with exit code $($process.ExitCode)"
                #         }
                #     }
                #     elseif ($executable.Extension -eq ".ps1") {
                #         & $executable.FullName
                #     }
                # }
                # else {
                #     # If no installer found, assume it's just files to extract to a location
                #     $destinationPath = Join-Path $env:ProgramFiles $AppName
                #     if (-not (Test-Path $destinationPath)) {
                #         New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
                #     }

                #     Copy-Item -Path "$ExtractPath\*" -Destination $destinationPath -Recurse -Force
                # }
            }
            default {
                throw "Unsupported installer type: $extension"
            }
        }

        Write-Host "$AppName installed successfully"
        return $true
    }
    catch {
        Write-Host "Installation failed: $_" -ForegroundColor Red

        if ($UseWingetFallback -and -not [string]::IsNullOrEmpty($WingetId)) {
            Write-Host "Attempting to install using winget"
            try {
                winget install -s winget -e --id $WingetId
                Write-Host "Winget installation completed"
                return $true
            }
            catch {
                Write-Host "Winget installation failed: $_" -ForegroundColor Red
                return $false
            }
        }

        return $false
    }
}

function Install-Dependencies {
    param(
        [object]$DependencyAsset,
        [string]$LocalCache,
        [string]$WorkDir
    )

    if (-not $DependencyAsset) {
        return $true
    }

    $dependencyPath = Get-Installer -Asset $DependencyAsset -LocalCache $LocalCache -WorkDir $WorkDir

    if (-not $dependencyPath) {
        Write-Host "Failed to get dependency installer" -ForegroundColor Red
        return $false
    }

    $extension = [System.IO.Path]::GetExtension($dependencyPath).ToLower()

    try {
        if ($extension -eq ".zip") {
            $extractPath = Join-Path $WorkDir "dependencies"
            Write-Host "Extracting dependencies to $extractPath"
            Expand-Archive -Path $dependencyPath -DestinationPath $extractPath -Force

            # Look for APPX or other packages to install
            $dependencies = Get-ChildItem -Path "$extractPath\x64" -Recurse -Include "*.appx", "*.msix", "*.appxbundle"

            if ($dependencies) {
                foreach ($dependency in $dependencies) {
                    Write-Host "Installing dependency: $($dependency.Name)"
                    Add-AppxPackage -Path $dependency.FullName -ErrorAction Continue
                }
            }
            else {
                Write-Host "No dependencies found to install in the extracted files"
            }
        }
        elseif ($extension -eq ".appx" -or $extension -eq ".msix" -or $extension -eq ".appxbundle") {
            Write-Host "Installing dependency: $dependencyPath"
            Add-AppxPackage -Path $dependencyPath -ErrorAction Stop
        }

        return $true
    }
    catch {
        Write-Host "Dependency installation failed: $_" -ForegroundColor Red
        return $false
    }
}

function Invoke-PostInstallActions {
    param(
        [scriptblock]$ScriptBlock,
        [string]$AppPath
    )

    if ($null -eq $ScriptBlock) {
        return
    }

    try {
        Write-Host "Executing post-installation actions"
        & $ScriptBlock $AppPath
        Write-Host "Post-installation actions completed"
    }
    catch {
        Write-Host "Post-installation actions failed: $_" -ForegroundColor Red
    }
}

function Complete-Installation {
    param(
        [string]$WorkDir,
        [bool]$Cleanup = $true
    )

    if ($Cleanup) {
        try {
            Remove-Item -Path $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Cleanup completed"
        }
        catch {
            Write-Host "Cleanup failed: $_" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Skipping cleanup as requested"
    }

    Write-Host "Installation process completed"
    Stop-Transcript
}

function Install-App {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$AppName,

        [Parameter(Mandatory = $true)]
        [string]$GitHubRepo,

        [Parameter(Mandatory = $true)]
        [string]$AssetFilter,

        [string]$WingetId = "",

        [scriptblock]$PostInstallAction,

        [string]$DependenciesFilter = "",

        [string]$DependencySubPath = "",

        [switch]$UseWingetFallback,

        [switch]$NoCleanup
    )

    # Main script execution
    try {
        $installInfo = Initialize-Installation -AppName $AppName -BasePath $BasePath

        $releaseInfo = Get-LatestRelease -GitHubRepo $GitHubRepo -AssetFilter $AssetFilter -DependenciesFilter $DependenciesFilter

        if (-not $releaseInfo) {
            throw "Failed to get release information"
        }

        $installerPath = Get-Installer -Asset $releaseInfo.MainAsset -LocalCache $installInfo.LocalCache -WorkDir $installInfo.WorkDir

        if (-not $installerPath) {
            if ($UseWingetFallback -and -not [string]::IsNullOrEmpty($WingetId)) {
                Write-Host "Installer not found, using winget fallback"
                winget install -s winget -e --id $WingetId
            }
            else {
                throw "Failed to get installer"
            }
        }
        else {
            if ($releaseInfo.DependencyAsset) {
                $dependencySuccess = Install-Dependencies -DependencyAsset $releaseInfo.DependencyAsset -LocalCache $installInfo.LocalCache -WorkDir $installInfo.WorkDir

                if (-not $dependencySuccess) {
                    Write-Host "Warning: Dependency installation failed, continuing with main installation" -ForegroundColor Yellow
                }
            }

            $installSuccess = Install-Application -InstallerPath $installerPath -AppName $AppName -WorkDir $installInfo.WorkDir -ExtractPath $installInfo.ExtractPath -WingetId $WingetId -UseWingetFallback $UseWingetFallback

            if (-not $installSuccess -and $UseWingetFallback -and -not [string]::IsNullOrEmpty($WingetId)) {
                Write-Host "Installation failed, using winget fallback"
                winget install -s winget -e --id $WingetId
            }
        }

        Invoke-PostInstallActions -ScriptBlock $PostInstallAction -AppPath $installInfo.ExtractPath
    }
    catch {
        Write-Host "Installation process failed: $_" -ForegroundColor Red

        if ($UseWingetFallback -and -not [string]::IsNullOrEmpty($WingetId)) {
            Write-Host "Using winget as fallback"
            winget install -s winget -e --id $WingetId
        }
    }
    finally {
        if ($installInfo) {
            Complete-Installation -WorkDir $installInfo.WorkDir -Cleanup (-not $NoCleanup)
        }
    }
}
