import os
import sys
from pathlib import Path

import click
import daemoniker
from psutil import pid_exists
from docker_hosts import os_is_windows, HOSTS_FILE_LOCATION_WINDOWS, os_is_linux, HOSTS_FILE_LOCATION_LINUX, os_is_mac, \
    HOSTS_FILE_LOCATION_MAC, get_mode, DockerHosts


def get_pid_file() -> str:
    pid_dir = os.environ.get(
        "DOCKER_HOSTS_PID_FILE",
        os.path.join(str(Path.home()), '.config', 'docker-hosts')
    )
    if not os.path.isdir(pid_dir):
        os.makedirs(pid_dir)

    return os.path.join(pid_dir, "docker-hosts.pid")


def get_host_file_path():
    _hosts_file_path = None
    if 'DOCKER_HOSTS_FILE_PATH' in os.environ:
        hosts_file_path = os.getenv('DOCKER_HOSTS_FILE_PATH')
        if os.path.isfile(hosts_file_path):
            _hosts_file_path = hosts_file_path
        else:
            print('Warning: File does not exist: {hosts_file_path}'.format(
                hosts_file_path=hosts_file_path
            ))
    else:
        if os_is_windows():
            _hosts_file_path = HOSTS_FILE_LOCATION_WINDOWS

        if os_is_linux():
            _hosts_file_path = HOSTS_FILE_LOCATION_LINUX

        if os_is_mac():
            _hosts_file_path = HOSTS_FILE_LOCATION_MAC
    return _hosts_file_path


@click.group()
def cli() -> None:
    pass


@cli.command("start")
@click.option("--no-daemon", is_flag=True, flag_value=True, default=False)
def start(no_daemon: bool) -> None:

    mode = get_mode()
    host_file_path = get_host_file_path()

    if no_daemon:
        try:
            DockerHosts(mode, host_file_path).run()
        except KeyboardInterrupt:
            pass
        finally:
            DockerHosts(mode, host_file_path).cleanup()
    else:
        with daemoniker.Daemonizer() as (_, daemonizer):
            try:
                is_parent, *_ = daemonizer(get_pid_file())
                DockerHosts(mode, host_file_path).run()
            except SystemExit as e:
                if str(e) == 'Unable to acquire PID file.':
                    with open(get_pid_file()) as f:
                        pid = int(f.read())
                    if pid_exists(pid):
                        sys.exit(0)
                    os.remove(get_pid_file())


@cli.command("stop")
def stop() -> None:
    mode = get_mode()
    host_file_path = get_host_file_path()
    if not os.path.isfile(get_pid_file()):
        print("Warning: docker-host was not running!")
    else:
        daemoniker.send(get_pid_file(), daemoniker.SIGINT)
    DockerHosts(mode, host_file_path).cleanup()


if __name__ == '__main__':
    cli()
