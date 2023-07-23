# Download Locationi
$localDirectory = Join-Path -Path C:\ -ChildPath "HIT_NHCA_UNIV_CONFIG"
    
while (-not $validURL) {
    # Ask for the repository URL
    $repoURL = Read-Host "Enter the GitHub Repository URL. (Leave blank to exit)"
    

    if (-not $repoURL) {
        Write-Host "Exiting the script."
        exit 1
    }

    # Extract the repository owner and name from the URL
    $regexPattern = 'github.com/(.+)/(.+?)(?:\.git)?$'
    if ($repoURL -match $regexPattern) {
        $repoOwner = $matches[1]
        $repoName = $matches[2]
        
    }
    else {
        Write-Host "Invalid GitHub Repository URL."
        continue
    }
    
    # Function to recursively download files and directories
    function Download-RepoContents {
        param (
            [object]$contents,
            [string]$basePath
        )
        foreach ($item in $contents) {
            $itemUrl = $item.download_url
            $itemPath = Join-Path -Path $basePath -ChildPath $item.name

            if ($item.type -eq "dir") {
                if (-not (Test-Path -Path $itemPath -PathType Container)) {
                    New-Item -ItemType Directory -Path $itemPath | Out-Null
                }

                # Recursive call to handle directory contents
                $subContents = Invoke-RestMethod -Uri $item.url
                Download-RepoContents -contents $subContents -basePath $itemPath
            }
            else {
                # Download the file
                Invoke-WebRequest -Uri $itemUrl -OutFile $itemPath
            }
        }
    }
    Write-Host $isDownloaded
    while (-not $isDownloaded) {
        try {
            Write-Host "Downloading repository contents..."
            $repoContents = Invoke-RestMethod -Uri "https://api.github.com/repos/$repoOwner/$repoName/contents"
            New-Item -ItemType Directory -Path $localDirectory | Out-Null
            Download-RepoContents -contents $repoContents -basePath $localDirectory 
            Write-Host "Repository downloaded successfully to: $localDirectory"
            $validURL = $true
            $isDownloaded = $true
        }
        catch {
            Write-Host "Failed to download repository contents. Error: $_"
            $choice = Read-Host "Do you want to retry? (Yes/No)"
            if ($choice -ne "Yes") {
                $isDownloaded = $true
            }

            else {
                if (Test-Path -Path $localDirectory -PathType Container) {
                    Remove-Item -Path $localDirectory -Recurse -Force
                }
                $isDownloaded = $false
                $repoURL = $null
            }
        }
    }
}
