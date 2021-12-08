# Copyright KubeSphere Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This is used to build KubeSphere, which basically contains all the tools
# necessary to perform and all build activities in KubeSphere repos.

###########
# Base OS
###########

FROM ubuntu:focal as base_os_context

ENV DEBIAN_FRONTEND=noninteractive

ENV DOCKER_VERSION=5:20.10.6~3-0~ubuntu-focal
ENV CONTAINERD_VERSION=1.4.6-1
ENV KUBERNETES_VERSION=v1.21.1

# required for binary tools: ca-certificates, gcc, libc-dev, git, iptables, libltdl7
# required for general build: make, wget, curl, ssh, rpm
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    curl \
    gnupg-agent \
    git \
    make

# Install kube-apiserver and kubectl
ADD https://dl.k8s.io/${KUBERNETES_VERSION}/kubernetes-server-linux-amd64.tar.gz /tmp
RUN tar -xvzf /tmp/kubernetes-server-linux-amd64.tar.gz -C /tmp
RUN mv /tmp/kubernetes/server/bin/kubectl /usr/local/bin/

# Docker including docker-ce, docker-ce-cli, and containerd.io
ADD https://download.docker.com/linux/ubuntu/gpg /tmp/docker-key
RUN apt-key add /tmp/docker-key
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
RUN apt-get update
RUN apt-get -y install --no-install-recommends docker-ce="${DOCKER_VERSION}" docker-ce-cli="${DOCKER_VERSION}" containerd.io="${CONTAINERD_VERSION}"

# Install github cli
ADD https://cli.github.com/packages/githubcli-archive-keyring.gpg /tmp/github-key
RUN apt-key add /tmp/github-key
RUN add-apt-repository "deb [arch=amd64] https://cli.github.com/packages stable main"
RUN apt-get update
RUN apt-get -y install --no-install-recommends gh

# Clean up stuff we don't need in the final image
RUN rm -rf /var/lib/apt/lists/*
RUN rm -fr /usr/share/bash-completion
RUN rm -fr /usr/share/bug
RUN rm -fr /usr/share/doc
RUN rm -fr /usr/share/locale
RUN rm -fr /usr/share/man
RUN rm -fr /tmp/*

###############
# Final Image
###############

FROM scratch as build_tools

# Version from build arguments
ARG VERSION

# Labels used by Docker
LABEL "io.kubesphere.repo"="https://github.com/kubesphere/test-infra"
LABEL "io.kubesphere.version"="${VERSION}"

# General
ENV HOME=/home
ENV LANG=C.UTF-8

# Create the file system
COPY --from=base_os_context / /

# mountpoints are mandatory for any host mounts.
# mountpoints in /config are special.
RUN mkdir -p /config/.docker && \
    mkdir -p /config/.kube && \
    mkdir -p /home/.cache

# They are created as root 755.  As a result they are not writeable, which fails in
# the developer environment as a volume or bind mount inherits the permissions of
# the directory mounted rather then overridding with the permission of the volume file.
RUN chmod 777 /config && \
    chmod 777 /config/.docker && \
    chmod 777 /config/.kube && \
    chmod 777 /home/.cache

WORKDIR /
CMD ["sh"]
