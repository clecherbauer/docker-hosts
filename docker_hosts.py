import json
import re
import shutil
import sys
import os
import time
import platform
import traceback
from dataclasses import dataclass
from pathlib import Path
from subprocess import check_output
from typing import List


HOSTS_FILE_LOCATION_WINDOWS = "C:\\Windows\\System32\\Drivers\\etc\\hosts"
HOSTS_FILE_LOCATION_LINUX = "/etc/hosts"
HOSTS_FILE_LOCATION_MAC = "/etc/hosts"
HOST_FILE_TMP = 'hosts.edit'

MODE_DOCKER = 'native'
MODE_DOCKER_DESKTOP = 'docker-desktop'
MODES = [
    MODE_DOCKER,
    MODE_DOCKER_DESKTOP
]

MARKER = "# !!! managed by clecherbauer/docker-hosts !!!"


def os_is_windows():
    system = platform.system()
    if system == "Windows" or system.startswith('CYGWIN_NT'):
        return True
    return False


def os_is_linux():
    system = platform.system()
    if system == "Linux":
        return True
    return False


def os_is_mac():
    system = platform.system()
    if system == "Darwin":
        return True
    return False


def get_mode():
    _mode = None
    if 'DOCKER_HOSTS_MODE' in os.environ:
        mode = os.getenv('DOCKER_HOSTS_MODE')
        if mode in MODES:
            _mode = mode
        else:
            print('Warning: Unrecognized mode: {mode}'.format(mode=mode))
            print('Available modes are {modes}'.format(modes=",".join(MODES)))
    else:
        if os_is_linux():
            _mode = MODE_DOCKER
        if os_is_windows() or os_is_mac():
            _mode = MODE_DOCKER_DESKTOP
    return _mode


@dataclass
class Host:
    ip: str
    aliases: [str]


class DockerHosts:
    hosts: List[Host] = []
    mode: str = None
    hosts_file_path: str = None
    should_run = False

    def __init__(self, mode, hosts_file_path):
        self.mode = mode
        self.hosts_file_path = hosts_file_path

    def run(self):
        self.should_run = True
        while self.should_run:
            try:
                hosts = self.get_hosts()
                self.modify_hosts_file(hosts)
                time.sleep(5)
            except Exception:
                traceback.print_exc()

    def stop(self):
        self.should_run = False
        self.cleanup()

    def get_hosts(self) -> []:
        hosts = []
        container_ids = self.get_running_docker_container_ids()
        for container_id in container_ids:
            container_attributes = self.get_container_attributes(container_id)
            network_settings = container_attributes.get('NetworkSettings', {})
            for key, network in network_settings.get('Networks', []).items():
                ip = network.get('IPAddress', None)
                if self.mode == MODE_DOCKER_DESKTOP:
                    ip = self.resolve_docker_desktop_host_ip()
                if ip:
                    aliases = []
                    resolved_aliases = network.get('Aliases', [])
                    if resolved_aliases:
                        for resolved_alias in resolved_aliases:
                            if '.' not in resolved_alias:
                                aliases.append('{resolved_alias}.{network}'.format(
                                    resolved_alias=resolved_alias,
                                    network=key)
                                )
                            else:
                                aliases.append(resolved_alias)
                        hosts.append(Host(
                            ip=ip,
                            aliases=aliases
                        ))
        return hosts

    @staticmethod
    def get_running_docker_container_ids() -> []:
        command = []
        if os_is_linux() or os_is_mac():
            command = ["env", "docker", "ps", "--format", "{{.ID}}"]
        if os_is_windows():
            command = ["docker", "ps", "--format", "{{.ID}}"]

        try:
            out = check_output(command).decode(sys.getdefaultencoding())
            ids = out.split("\n")
            ids[:] = [x for x in ids if x]
            return ids
        except Exception:
            traceback.print_exc()
            return []

    @staticmethod
    def get_container_attributes(container_id: str) -> {}:
        command = []
        if os_is_linux() or os_is_mac():
            command = ["env", "docker", "inspect", container_id]
        if os_is_windows():
            command = ["docker", "inspect", container_id]
        try:
            out = check_output(command).decode(sys.getdefaultencoding())
            return json.loads(out)[0]
        except Exception:
            traceback.print_exc()
            return {}

    def modify_hosts_file(self, hosts):
        original_lines = self.get_host_file_lines()
        new_lines = []
        for index, original_line in enumerate(original_lines):
            if not original_line.startswith(MARKER) and \
                    not (index > 0 and original_lines[index - 1].startswith(MARKER)):
                new_lines.append(original_line)

        for host in hosts:
            new_lines.append(MARKER)
            new_lines.append("{ip}      {aliases}".format(
                ip=host.ip,
                aliases=" ".join(host.aliases)
            ))

        original_lines_hash = hash(str(original_lines))
        new_lines_hash = hash(str(new_lines))
        if not original_lines_hash == new_lines_hash:
            tmp_file_path = os.path.join(os.path.dirname(self.hosts_file_path), HOST_FILE_TMP)
            self.save_copy(self.hosts_file_path, tmp_file_path)
            with open(tmp_file_path, mode='w', encoding=sys.getdefaultencoding()) as new_file:
                new_file.write('\n'.join(new_lines))
            self.save_copy(tmp_file_path, self.hosts_file_path)
            os.remove(tmp_file_path)

    def get_host_file_lines(self) -> List[str]:
        with open(self.hosts_file_path, mode='r', encoding=sys.getdefaultencoding()) as file:
            return file.read().split('\n')

    def resolve_docker_desktop_host_ip(self):
        if os_is_windows() or os_is_mac():
            host_file_lines = self.get_host_file_lines()
            for host_file_line in host_file_lines:
                if 'host.docker.internal' in host_file_line:
                    ip = re.findall(r'[0-9]+(?:\.[0-9]+){3}', host_file_line)
                    if len(ip) > 0:
                        return ip[0]
        return 'none'

    @staticmethod
    def save_copy(source, target):
        shutil.copy2(source, target)
        if os_is_linux() or os_is_mac():
            st = os.stat(source)
            os.chown(target, st.st_uid, st.st_gid)

    def cleanup(self):
        self.modify_hosts_file([])
