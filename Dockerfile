FROM ubuntu:bionic

ENV DOCKER_COMPOSE_VERSION=1.26.0
ENV ANSIBLE_VERSION=2.9.12.0
ENV MOLECULE_VERSION=3.0.6
ENV ENTRYKIT_VERSION=0.4.0

# Needed to prevent errors from Click (used by molecule):
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN apt-get update \
    && apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common \
        rsyslog \
        python3-pip \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" \
    && apt-get update \
    && apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
    && pip3 install --no-cache-dir \
        ansible==${ANSIBLE_VERSION} \
        molecule==${MOLECULE_VERSION} \
        docker \
        ansible-lint \
    && curl -L https://github.com/progrium/entrykit/releases/download/v${ENTRYKIT_VERSION}/entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz | tar zx \
    && chmod +x entrykit \
    && mv entrykit /bin/entrykit \
    && entrykit --symlink \
    && mkdir -p /etc/docker \
    && echo '{ "storage-driver": "vfs" }' > /etc/docker/daemon.json \
    && rm -rf /var/cache/apt/archives \
    && rm -rf /var/lib/apt/lists/*
