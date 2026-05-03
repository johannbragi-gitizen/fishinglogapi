param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$DestinationPath,

    [Parameter(Mandatory = $true)]
    [string]$SiteName,

    [Parameter(Mandatory = $true)]
    [string]$AppPoolName
)

$ErrorActionPreference = 'Stop'

Import-Module WebAdministration

if (-not (Test-Path $SourcePath)) {
    throw "Source path does not exist: $SourcePath"
}

if (-not (Test-Path "IIS:\\AppPools\\$AppPoolName")) {
    throw "IIS app pool '$AppPoolName' does not exist."
}

if (-not (Test-Path "IIS:\\Sites\\$SiteName")) {
    throw "IIS site '$SiteName' does not exist."
}

if (-not (Test-Path $DestinationPath)) {
    New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
}

Write-Host "Stopping IIS site and app pool..."
Stop-Website -Name $SiteName
Stop-WebAppPool -Name $AppPoolName

Write-Host "Copying published files to $DestinationPath..."
robocopy $SourcePath $DestinationPath /MIR /R:2 /W:2 /NFL /NDL /NP /NJH /NJS
$robocopyExitCode = $LASTEXITCODE
if ($robocopyExitCode -ge 8) {
    throw "Robocopy failed with exit code $robocopyExitCode"
}

Write-Host "Starting IIS app pool and site..."
Start-WebAppPool -Name $AppPoolName
Start-Website -Name $SiteName

Write-Host "Deployment complete."
