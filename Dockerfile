FROM debian:bullseye-slim

COPY docker-hosts.linux64.zip .

RUN apt update
RUN apt install docker.io zip -y
RUN unzip docker-hosts.linux64.zip
RUN cp docker-hosts/docker-hosts /usr/local/bin

ENV DOCKER_HOSTS_MODE=native
ENV DOCKER_HOSTS_FILE_PATH=/etc/hosts

RUN mkdir -p "$HOME/.config/docker-hosts/"

ENTRYPOINT /usr/local/bin/docker-hosts start --no-daemon
