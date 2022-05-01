#Requires -RunAsAdministrator
#Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"

$VERSION = "v1.2.0"
$SOURCE_FILE = "docker-hosts.win64.zip"
$SOURCE_DIR = "docker-hosts"

$confirmation = Read-Host "Are you sure you want To proceed? [y/n]"
if ($confirmation -match "[yY]") {
    $releases = Invoke-WebRequest "https://gitlab.com/api/v4/projects/35657590/releases/$VERSION/assets/links" -UseBasicParsing | ConvertFrom-Json

    $zip_url = $null
    
    foreach ($release in $releases){
        if ($release[0].name -eq 'Windows Executable') {
            $zip_url = $release[0].direct_asset_url
        } 
    }
    Invoke-WebRequest -Uri $zip_url -OutFile docker-hosts.win64.zip
    Expand-Archive -Path docker-hosts.win64.zip -DestinationPath "C:\\Program Files\\" -Force
    & C:\docker-hosts\setup.ps1 intall
    if (Test-Path -Path docker-host.win64.zip) {
        Remove-Item docker-hosts.win64.zip -Force
    }
}
