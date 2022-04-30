# docker-hosts

Automatically manages entries in hosts file (`/etc/hosts`) for local and remote [docker](https://docker.io/) containers.

Its main use-case is working on multiple web-accessible projects without having to keep track of different exported ports, instead relying on predictable names.

Inspired by [`costela/docker-etchosts`](https://github.com/costela/docker-etchosts).

## Supported Setups
- linux 
- macOS with Docker-Desktop
- 

## Installation

It's possible to run `docker-hosts` from inside a docker container itself, giving it access to both the hosts file and the docker daemon:
```
docker run -d \
  --network none --restart always \
  -v /etc/hosts:/etc/hosts -v /var/run/docker.sock:/var/run/docker.sock \
  clecherbauer/docker-hosts
```

Alternatively, you can also install `docker-hosts` directly:

Linux (Tested with Ubuntu 20.04)
```
wget -q -O - "https://raw.githubusercontent.com/clecherbauer/docker-hosts/1.0.0/linux/online-installer.sh" | sudo bash
```

MacOS
```
wget -q -O - "https://raw.githubusercontent.com/clecherbauer/docker-hosts/1.0.0/macos/online-installer.sh" | wheel bash
```

Windows (Tested with Windows 10)
```
download and install manually
```


## Usage

Once started, `docker-hosts` creates `/etc/hosts` entries for all existing containers within accessible networks.

This means the following `docker-compose.yml` setup for project `someproject`:
```yaml
services:
  someservice:
    networks:
      default:
        aliases:
          - somealias
```
Would generate the following hosts entry:
```
x.x.x.x      someproject-someservice.someproject_default someservice.someproject_default somealias <container_id>.someproject_default
```

_NOTE_: Docker ensures the uniqueness of containers' IP addresses and names, but does not ensure uniqueness for aliases. This may lead to multiple entries having the same name, especially for the shorter name versions. The longer, more explict, names are there to help in these cases, enabling different workflows with multiple projects.

To avoid overwriting unrelated entries, `docker-hosts` will not touch entries not managed by itself. If you already manually created hosts entries for IPs used by containers, you should remove them so that `docker-hosts` can take over management.

All entries managed by `docker-hosts` will be removed upon termination, returning the hosts file to its initial state.

## Configuration

`docker-hosts` can be configured with the following environment variables:

- **`DOCKER_HOSTS_MODE`**: (default: `native`, possible values: `native` `docker-desktop`)

- **`DOCKER_HOSTS_FILE_PATH`**: path to hosts file (default `/etc/hosts`)
