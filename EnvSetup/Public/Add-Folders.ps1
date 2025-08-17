function Add-Folders {
    [CmdletBinding()]
    param()

    ## Source directories
    $sourcePath = Join-Path $env:USERPROFILE 'Source';

    # Create base directories
    New-Item -ItemType "Directory" -Path $sourcePath -Force;

    # Local structure
    $localPath = Join-Path $sourcePath 'local';
    New-Item -ItemType "Directory" -Path $localPath -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $localPath '!nuget') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $localPath '_git-bare') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $localPath 'archives') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $localPath 'docs') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $localPath 'knowledgebase') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $localPath 'sandbox') -Force;

    # Personal notes structure
    $basePath = Join-Path $localPath 'docs\personal';
    New-Item -ItemType "Directory" -Path $basePath -Force;
    New-Item -ItemType "File" -Path (Join-Path $basePath '.gitattributes') -Force;
    "*.env" | Set-Content -Encoding UTF8 -Path (Join-Path $basePath '.gitignore') -Force;
    "root = true" | Set-Content -Encoding UTF8 -Path (Join-Path $basePath '.editorconfig') -Force;
    "*" | Set-Content -Encoding UTF8 -Path (Join-Path $basePath '.copilotignore') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $basePath '.vscode') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $basePath '.workspaces') -Force;

    # Home structure
    $homePath = Join-Path $basePath 'home';
    New-Item -ItemType "Directory" -Path $homePath -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $homePath 'trash') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $homePath 'dump') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $homePath 'temp') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $homePath 'public') -Force;

    # Private section
    $privatePath = Join-Path $homePath 'private';
    New-Item -ItemType "Directory" -Path $privatePath -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $privatePath 'backups') -Force;

    # Global section
    $globalPath = Join-Path $homePath 'global';
    New-Item -ItemType "Directory" -Path $globalPath -Force;
    New-Item -ItemType "File" -Path (Join-Path $globalPath 'Diary.md') -Force;

    # Dev section
    $devPath = Join-Path $globalPath 'dev';
    New-Item -ItemType "Directory" -Path $devPath -Force;
    New-Item -ItemType "File" -Path (Join-Path $devPath 'Scratchpad.md') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $devPath 'tickets') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $devPath 'projects') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $devPath 'repositories') -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $devPath 'middleware') -Force;

    # GitHub root
    $githubPath = Join-Path $sourcePath 'github';
    New-Item -ItemType "Directory" -Path $githubPath -Force;
    New-Item -ItemType "Directory" -Path (Join-Path $githubPath "$env:username") -Force;

    # Others...
    # New-Item -ItemType "Directory" -Path (Join-Path $sourcePath 'vsts') -Force
    # New-Item -ItemType "Directory" -Path (Join-Path $sourcePath 'bitbucket') -Force
    # New-Item -ItemType "Directory" -Path (Join-Path $sourcePath 'gitlab') -Force
    # New-Item -ItemType "Directory" -Path (Join-Path $sourcePath 'assembla') -Force
}
