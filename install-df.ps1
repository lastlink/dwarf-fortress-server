$ErrorActionPreference = 'Stop'
$failed = $false
trap { $failed = $true }

# Define the relative base path
$baseFolder = (Get-Location).Path

Write-Output "Base folder is set to: $baseFolder"
$basePath = "$baseFolder\dwarf_fortress"
# absolute path
# "$(HOME)\dwarf_fortress"

# Create directories
if (-not (Test-Path -Path "$basePath")) {
    New-Item -ItemType Directory -Path "$basePath"
    Write-Output "Dwarf fortress directory created."
} else {
    Write-Output "Dwarf fortress directory already exists, skipping..."
}

if (-not (Test-Path -Path "$basePath\saves")) {
    New-Item -ItemType Directory -Path "$basePath\saves"
    Write-Output "Save directory created."
} else {
    Write-Output "Save directory already exists, skipping..."
}

# Create temporary installation directory
New-Item -ItemType Directory -Path "df_install"
Set-Location -Path "df_install"

# Download Dockerfile
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kahveciderin/dwarf-fortress-server/master/Dockerfile" -OutFile "Dockerfile"

# Build and run Docker container
docker build -t dfserver .
docker run -d --restart always --privileged -p 8764:1234 -p 5000:5000 -v "$basePath\saves:/df/df_linux/data/save" -it dfserver

# Clean up temporary installation directory
Set-Location -Path ".."
Remove-Item -Path "df_install" -Recurse -Force

# # Check for errors
if (-not $failed) {
    Write-Output "Server should be up and running on port 8764!"
} else {
    Write-Output "Encountered error, deleting all containers"
    docker stop (docker ps -a -q)
    docker rm (docker ps -a -q)
    Remove-Item -Path "df_install" -Recurse -Force
}
