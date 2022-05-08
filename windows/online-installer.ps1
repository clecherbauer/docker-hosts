#Requires -RunAsAdministrator
#Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"

$VERSION = "v1.2.1"
$SOURCE_FILE = "docker-hosts.win64.zip"
$SOURCE_DIR = "docker-hosts"

$releases = Invoke-WebRequest "https://gitlab.com/api/v4/projects/35657590/releases/$VERSION/assets/links" -UseBasicParsing | ConvertFrom-Json

$zip_url = $null

foreach ($release in $releases){
    if ($release[0].name -eq 'Windows Executable') {
        $zip_url = $release[0].direct_asset_url
    }
}
Invoke-WebRequest -Uri $zip_url -OutFile docker-hosts.win64.zip

$service = Get-Service -Name docker-hosts -ErrorAction SilentlyContinue
if ($service.Length -gt 0) {
    & 'C:\Program Files\docker-hosts\docker-hosts.exe' stop
    Start-Sleep -s 5
}

Expand-Archive -Path docker-hosts.win64.zip -DestinationPath "C:\Program Files\" -Force
& 'C:\Program Files\docker-hosts\setup.ps1' install
if (Test-Path -Path docker-host.win64.zip) {
    Remove-Item docker-hosts.win64.zip -Force
}
