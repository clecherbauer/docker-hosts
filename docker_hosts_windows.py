import sys

import servicemanager
import win32event
import win32service
import win32serviceutil

from docker_hosts import DockerHosts, get_mode
from docker_hosts_unix import get_host_file_path


class DockerHostsWindowsService(win32serviceutil.ServiceFramework):
    _svc_name_ = "DockerHosts"
    _svc_display_name_ = "DockerHosts Service"
    _svc_description_ = "Automatically manages entries in hosts file for local and remote docker containers."
    docker_hosts = None

    def SvcStop(self):
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        self.docker_hosts.stop()
        self.ReportServiceStatus(win32service.SERVICE_STOPPED)

    def SvcDoRun(self):
        self.ReportServiceStatus(win32service.SERVICE_START_PENDING)
        mode = get_mode()
        host_file_path = get_host_file_path()
        self.docker_hosts = DockerHosts(mode, host_file_path)
        self.ReportServiceStatus(win32service.SERVICE_RUNNING)
        self.docker_hosts.run()


if __name__ == '__main__':
    if len(sys.argv) == 1:
        servicemanager.Initialize()
        servicemanager.PrepareToHostSingle(DockerHostsWindowsService)
        servicemanager.StartServiceCtrlDispatcher()
    else:
        win32serviceutil.HandleCommandLine(DockerHostsWindowsService)
else:
    win32serviceutil.HandleCommandLine(DockerHostsWindowsService)
