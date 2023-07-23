param (
    [string]$repositoryUrl,
    [string]$localDirectory
)

# Validate input parameters
if (-not $repositoryUrl -or -not $localDirectory) {
    Write-Host "Usage: .\Download-GitHubRepo.ps1 -repositoryUrl <RepositoryURL> -localDirectory <LocalDirectory>"
    exit 1
}

# Extract the repository owner and name from the URL
$regexPattern = 'github.com/(.+)/(.+?)(?:\.git)?$'
if ($repositoryUrl -match $regexPattern) {
    $repoOwner = $matches[1]
    $repoName = $matches[2]
}
else {
    Write-Host "Invalid GitHub repository URL."
    exit 1
}

# Get the repository contents using GitHub API
$baseUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents"
$repoContents = Invoke-RestMethod -Uri $baseUrl

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

# Start downloading the repository contents
try {
    Write-Host "Downloading repository contents..."
    Download-RepoContents -contents $repoContents -basePath $localDirectory
    Write-Host "Repository downloaded successfully to: $localDirectory"
}
catch {
    Write-Host "Failed to download repository contents. Error: $_"
}
