#Requires -RunAsAdministrator

function install {
    & "C:\\Program Files\\docker-hosts\\docker-hosts.exe --stop"
    & "C:\\Program Files\\docker-hosts\\docker-hosts.exe --startup=auto install"
    & "C:\\Program Files\\docker-hosts\\docker-hosts.exe --start"
}

function uninstall {
    & "C:\\Program Files\\docker-hosts\\docker-hosts.exe --stop"
    & "C:\\Program Files\\docker-hosts\\docker-hosts.exe --remove"
    if (Test-Path -Path "C:\\Program Files\\docker-hosts\\") {
       Remove-Item "C:\\Program Files\\docker-hosts\\" -Recurse -Force -Confirm:$false
    }
}

if ($args[0] -eq 'install') {
    install
}

if ($args[0] -eq 'uninstall') {
    uninstall
}
