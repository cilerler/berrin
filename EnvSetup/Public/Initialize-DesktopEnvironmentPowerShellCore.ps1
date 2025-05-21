function Initialize-DesktopEnvironmentPowerShellCore {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BasePath,

        [Parameter()]
        [string]$TerminalBackgroundImagePath
    )

    Write-Verbose "Continuing desktop environment initialization..."

    Write-Verbose "Installling Terminal"
    Install-App `
        -BasePath $BasePath `
        -AppName "terminal" `
        -GitHubRepo "microsoft/terminal" `
        -AssetFilter "*_x64.zip" `
        -UseWingetFallback `
        -WingetId "Microsoft.WindowsTerminal" `
        -NoCleanup `
        -PostInstallAction {
        param($AppPath)
        Start-Transcript -Path (Join-Path $env:TEMP "$($MyInvocation.MyCommand.Name).log");
        Write-Host "Starting '$($MyInvocation.MyCommand.Name)'";
        Write-Host "AppPath '$AppPath'";

        # Create a shortcut to the Windows Terminal executable in the extracted folder
        $exeName = 'WindowsTerminal.exe'
        $exeFile = Get-ChildItem -Path $AppPath -Recurse -Filter $exeName | Select-Object -First 1
        if (-not $exeFile) {
            Throw "Could not find $exeName under $AppPath"
        }

        # Create shortcut on desktop
        $shortcutPath = Join-Path $env:USERPROFILE 'Desktop\Windows Terminal.lnk'
        $wShell = New-Object -ComObject WScript.Shell
        $shortcut = $wShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $exeFile.FullName
        $shortcut.WorkingDirectory = $exeFile.DirectoryName
        $shortcut.IconLocation = "$($exeFile.FullName),0"
        $shortcut.Save()
        Write-Host "Shortcut created at $shortcutPath -> $($exeFile.FullName)"

        # Find the settings path
        $pkg = Get-AppxPackage -Name Microsoft.WindowsTerminal -ErrorAction SilentlyContinue

        if ($pkg) {
            $installDir = $pkg.InstallLocation
            $settingsPath = Join-Path $env:LOCALAPPDATA "Packages\$($pkg.PackageFamilyName)\LocalState\settings.json"
        }
        else {
            # Assume the ZIP/portable build
            $portableRoot = Join-Path $env:TEMP 'terminal\extracted'
            $latestVerDir = Get-ChildItem -Path $portableRoot -Directory `
            | Sort-Object LastWriteTime -Descending `
            | Select-Object -First 1

            if (-not $latestVerDir) {
                Throw "Couldn't find a portable Terminal under `$env:TEMP\terminal\extracted`."
            }

            $installDir = $latestVerDir.FullName
            $settingsPath = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
        }

        # Ensure destination exists
        New-Item -ItemType Directory -Path (Split-Path $settingsPath) -Force | Out-Null

        # Copy defaults.json → settings.json if missing
        $template = Join-Path $installDir 'defaults.json'
        if (-not (Test-Path $settingsPath)) {
            Copy-Item -Path $template -Destination $settingsPath -Force
            Write-Host "Created settings.json from defaults.json"
        }

        # Load settings file
        $settingsContent = Get-Content -Raw $settingsPath
        Write-Host "Loaded settings file from: $settingsPath"

        # Parse JSON with high depth
        $json = $settingsContent | ConvertFrom-Json -Depth 20

        # Check JSON structure and dump important information
        Write-Host "Settings JSON structure check:"
        Write-Host "- defaultProfile: $($json.defaultProfile)"
        Write-Host "- profiles type: $($json.profiles.GetType().Name)"
        Write-Host "- profiles count: $($json.profiles.Count)"

        # Find PowerShell profile
        $pwsh = $json.profiles | Where-Object {
                ($_.name -eq 'PowerShell' -and ($_.commandline -eq 'pwsh.exe' -or $_.source -eq 'Windows.Terminal.PowershellCore'))
        }

        if (-not $pwsh) {
            Write-Host "PowerShell Core profile not found. Creating one..."

            # Create a new PowerShell profile
            $newGuid = "{" + [Guid]::NewGuid().ToString() + "}"
            Write-Host "Generated new GUID: $newGuid"

            $pwshProfile = [PSCustomObject]@{
                guid              = $newGuid
                name              = "PowerShell"
                commandline       = "pwsh.exe"
                hidden            = $false
                colorScheme       = "Campbell"
                fontFace          = "Cascadia Mono"
                fontSize          = 12
                closeOnExit       = "automatic"
                cursorShape       = "bar"
                historySize       = 9001
                padding           = "8, 8, 8, 8"
                snapOnInput       = $true
                startingDirectory = "%USERPROFILE%"
                useAcrylic        = $false
            }

            # Add the profile to the profiles array
            # First convert to ArrayList for easier manipulation
            $profilesList = New-Object System.Collections.ArrayList
            foreach ($profile in $json.profiles) {
                [void]$profilesList.Add($profile)
            }
            [void]$profilesList.Add($pwshProfile)

            # Replace the profiles array with our new list
            $json.profiles = $profilesList

            # Get a reference to the newly added profile
            $pwsh = $pwshProfile
            Write-Host "Created new PowerShell profile with GUID: $($pwsh.guid)"

            # Set PowerShell as default profile
            $json.defaultProfile = $pwsh.guid
            Write-Host "Default profile set to: $($pwsh.guid)"
        }
        else {
            Write-Host "Found existing PowerShell profile with GUID: $($pwsh.guid)"

            # Make sure it's set as default
            if ($json.defaultProfile -ne $pwsh.guid) {
                $oldDefault = $json.defaultProfile
                $json.defaultProfile = $pwsh.guid
                Write-Host "Changed default profile from '$oldDefault' to '$($pwsh.guid)'"
            }
            else {
                Write-Host "PowerShell profile is already the default"
            }
        }

        # Add custom settings to the PowerShell profile
        $settingsToAdd = @{
            backgroundImage            = $TerminalBackgroundImagePath
            backgroundImageOpacity     = 0.1
            backgroundImageStretchMode = 'none'
            font                       = @{ face = 'CaskaydiaCove NF' }
        }

        # Apply settings to the profile
        foreach ($key in $settingsToAdd.Keys) {
            $value = $settingsToAdd[$key]

            # Special handling for 'font' property - PowerShell profiles might not have it
            if ($key -eq 'font' -and -not $pwsh.PSObject.Properties['font']) {
                Write-Host "Adding font property with face: $($value.face)"
                $pwsh | Add-Member -NotePropertyName $key -NotePropertyValue $value -Force
                continue
            }

            # For other properties
            if ($pwsh.PSObject.Properties[$key]) {
                Write-Host "Updating existing property: $key"
                $pwsh.$key = $value
            }
            else {
                Write-Host "Adding new property: $key"
                $pwsh | Add-Member -NotePropertyName $key -NotePropertyValue $value -Force
            }
        }

        # Verify the profile exists in the list
        $foundInList = $json.profiles | Where-Object { $_.guid -eq $pwsh.guid }
        if ($foundInList) {
            Write-Host "✅ Profile verification: Found profile with GUID $($pwsh.guid) in the profiles array"
        }
        else {
            Write-Host "⚠️ WARNING: Could not verify the profile in the list. This might cause issues."
        }

        # Save the modified settings back to file
        $jsonString = $json | ConvertTo-Json -Depth 20
        Set-Content -Path $settingsPath -Value $jsonString

        Write-Host "✅ Settings file updated at: $settingsPath"
        Write-Host "✅ PowerShell profile updated. Relaunch Windows Terminal to see it."
        Write-Host "Finishing '$($MyInvocation.MyCommand.Name)'";
        Stop-Transcript
    }

    Write-Verbose "Installling OhMyPosh"
    Install-App `
        -BasePath $BasePath `
        -AppName "ohmyposh" `
        -GitHubRepo "JanDeDobbeleer/oh-my-posh" `
        -AssetFilter "*-x64.msi" `
        -UseWingetFallback `
        -WingetId "JanDeDobbeleer.OhMyPosh" `
        -PostInstallAction {
        Install-Module -Name Terminal-Icons -Repository PSGallery -Force;

        $ohMyPoshFilePath = "$env:userprofile\source\local\docs\oh-my-posh-theme.omp.json";
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wiki/cilerler/cilerler.github.io/documents/oh-my-posh-theme.omp.json" -OutFile $ohMyPoshFilePath;

        $profilePath = $PROFILE;

        # Ensure the profile file exists
        if (-not (Test-Path $profilePath)) {
            New-Item -ItemType File -Path $profilePath -Force | Out-Null;
        }

        # Define the lines to append
        $linesToAdd = @"
function prompt
{
    return;
}
Import-Module -Name Terminal-Icons;
oh-my-posh --init --shell pwsh --config "$ohMyPoshFilePath" | Invoke-Expression;
"@

        # Check if the lines already exist to avoid duplicates
        if (-not (Get-Content $profilePath | Select-String 'oh-my-posh')) {
            Add-Content -Path $profilePath -Value $linesToAdd;
        }
    }
}
