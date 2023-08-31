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

###############
# Binary Tools
###############

ARG GOLANG_IMAGE=golang:1.20.7
FROM ${GOLANG_IMAGE} as binary_tools_context

# Versions of tools we used
ENV GOIMPORTS_VERSION=v0.1.0
ENV HELM3_VERSION=v3.4.2
ENV K8S_CODE_GENERATOR_VERSION=v0.21.2
ENV KIND_VERSION=v0.11.1
ENV KUBERNETES_VERSION=1.22.1
ENV SHELLCHECK_VERSION=v0.7.1
ENV SU_EXEC_VERSION=0.2
ENV YQ_VERSION=3.3.0

ENV GO111MODULE=on
ENV GOPROXY=https://proxy.golang.org

WORKDIR /tmp
ENV GOPATH=/tmp/go

ENV OUTDIR=/out
RUN mkdir -p ${OUTDIR}/usr/bin
RUN mkdir -p ${OUTDIR}/usr/local
RUN mkdir -p ${OUTDIR}/usr/local/bin

# Some kubebuilder e2e tests still use the following path
RUN mkdir -p ${OUTDIR}/usr/local/kubebuilder/bin

# Update distro and install dependencies
RUN apt update && apt install -y --no-install-recommends \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common \
    unzip \
    xz-utils

# Build and install Go tools
RUN go install golang.org/x/tools/cmd/goimports@${GOIMPORTS_VERSION}
RUN go install sigs.k8s.io/kind@${KIND_VERSION}

# Install etcd, kube-apiserver and kubectl
ADD https://storage.googleapis.com/kubebuilder-tools/kubebuilder-tools-${KUBERNETES_VERSION}-linux-amd64.tar.gz /tmp
RUN tar -xvzf kubebuilder-tools-${KUBERNETES_VERSION}-linux-amd64.tar.gz -C ${OUTDIR}/usr/local/

# Install the code generator tools
RUN GO111MODULE=on go install k8s.io/code-generator/cmd/client-gen@${K8S_CODE_GENERATOR_VERSION}
RUN GO111MODULE=on go install k8s.io/code-generator/cmd/lister-gen@${K8S_CODE_GENERATOR_VERSION}
RUN GO111MODULE=on go install k8s.io/code-generator/cmd/informer-gen@${K8S_CODE_GENERATOR_VERSION}
RUN GO111MODULE=on go install k8s.io/code-generator/cmd/deepcopy-gen@${K8S_CODE_GENERATOR_VERSION}

# ShellCheck linter
ADD https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz /tmp
RUN tar -xJf /tmp/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz -C /tmp
RUN mv /tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck ${OUTDIR}/usr/bin

# Helm version 3
ADD https://get.helm.sh/helm-${HELM3_VERSION}-linux-amd64.tar.gz /tmp
RUN mkdir /tmp/helm3
RUN tar -xf /tmp/helm-${HELM3_VERSION}-linux-amd64.tar.gz -C /tmp/helm3
RUN cp /tmp/helm3/linux-amd64/helm ${OUTDIR}/usr/bin/helm3
RUN mv /tmp/helm3/linux-amd64/helm ${OUTDIR}/usr/bin/helm

# Install su-exec which is a tool that operates like sudo without the overhead
ADD https://github.com/ncopa/su-exec/archive/v${SU_EXEC_VERSION}.tar.gz /tmp
RUN tar -xzvf v${SU_EXEC_VERSION}.tar.gz
WORKDIR /tmp/su-exec-${SU_EXEC_VERSION}
RUN make
RUN cp -a su-exec ${OUTDIR}/usr/bin

# move installed go tools
RUN mv /tmp/go/bin/* ${OUTDIR}/usr/bin

# Cleanup stuff we don't need in the final image
RUN rm -fr /usr/local/go/doc
RUN rm -fr /usr/local/go/test
RUN rm -fr /usr/local/go/api
RUN rm -fr /usr/local/go/bin/godoc


###########
# Base OS
###########

FROM ubuntu:focal as base_os_context

ENV DEBIAN_FRONTEND=noninteractive

ENV DOCKER_VERSION=5:20.10.6~3-0~ubuntu-focal
ENV CONTAINERD_VERSION=1.4.6-1

ENV OUTPUT=/out

# required for binary tools: ca-certificates, gcc, libc-dev, git, iptables, libltdl7
# required for general build: make, wget, curl, ssh, rpm
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    build-essential \
    software-properties-common \
    ca-certificates \
    gcc \
    git \
    ssh \
    iptables \
    make \
    pkg-config \
    wget \
    jq \
    gettext-base \
    locales-all


# Docker including docker-ce, docker-ce-cli, and containerd.io
ADD https://download.docker.com/linux/ubuntu/gpg /tmp/docker-key
RUN apt-key add /tmp/docker-key
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
RUN apt-get update
RUN apt-get -y install --no-install-recommends docker-ce="${DOCKER_VERSION}" docker-ce-cli="${DOCKER_VERSION}" containerd.io="${CONTAINERD_VERSION}"

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

# Go support
ENV GO111MODULE=on
ENV GOPROXY=https://proxy.golang.org
ENV GOSUMDB=sum.golang.org
ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV GOCACHE=/gocache
ENV GOBIN=/gobin
ENV PATH=/usr/local/go/bin:/gobin:/usr/local/kubebuilder/bin:$PATH

# Create the file system
COPY --from=base_os_context / /
COPY --from=binary_tools_context /out/ /
COPY --from=binary_tools_context /usr/local/go /usr/local/go

# COPY --from=nodejs_tools_context /usr/local/bin /usr/local/bin
# COPY --from=nodejs_tools_context /usr/local/lib/node_modules /usr/local/lib/node_modules
# COPY --from=nodejs_tools_context /node_modules /node_modules

COPY bashrc /home/.bashrc

# Run dockerd in CI
COPY entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint

# mountpoints are mandatory for any host mounts.
# mountpoints in /config are special.
RUN mkdir -p /go && \
    mkdir -p /gocache && \
    mkdir -p /config/.docker && \
    mkdir -p /config/.kube && \
    mkdir -p /config-copy && \
    mkdir -p /home/.cache && \
    mkdir -p /home/.helm

# They are created as root 755.  As a result they are not writeable, which fails in
# the developer environment as a volume or bind mount inherits the permissions of
# the directory mounted rather then overridding with the permission of the volume file.
RUN chmod 777 /go && \
    chmod 777 /gocache && \
    chmod 777 /config && \
    chmod 777 /config/.docker && \
    chmod 777 /config/.kube && \
    chmod 777 /home/.cache && \
    chmod 777 /home/.helm

WORKDIR /

ENTRYPOINT ["/usr/local/bin/entrypoint"]
