# Inspired by
# https://blog.realkinetic.com/building-minimal-docker-containers-for-python-applications-37d0272c52f3
# https://github.com/gaahrdner/docker-molecule
# https://github.com/docker-library/docker/tree/master/20.10
# https://github.com/docker-library/docker/tree/master/20.10/dind

FROM ubuntu:bionic as base

### Phase 1: prepare Docker, dind, python3 ###

FROM base as builder

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN apt-get update && \
	apt-get install -y \
		wget

RUN set -eux; \
    \
	url='https://download.docker.com/linux/static/stable/x86_64/docker-20.10.1.tgz'; \
	\
	wget -q -O docker.tgz "$url"; \
	\
	mkdir /docker; \
	\
	tar --extract \
		--file docker.tgz \
		--strip-components 1 \
		--directory /docker

ENV DIND_COMMIT ed89041433a031cafc0a0f19cfe573c31688d377

RUN set -eux; \
	mkdir /dind; \
	wget -q -O /dind/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; \
	chmod +x /dind/dind

# Install Ansible, Molecule, docker-compose
ENV DOCKER_COMPOSE_VERSION=1.26.0
ENV ANSIBLE_VERSION=2.9.12.0
ENV MOLECULE_VERSION=3.0.6

RUN apt-get install -y \
		python3-pip \
	&& pip3 install --upgrade pip \
	&& python3 -m pip install --prefix=/python \
		ansible==${ANSIBLE_VERSION} \
		molecule==${MOLECULE_VERSION} \
		docker \
		docker-compose==${DOCKER_COMPOSE_VERSION} \
		ansible-lint

### Phase 2: create final image ###

FROM base

# Needed to prevent errors from Click (used by molecule):
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Fix python weirdness:
RUN mkdir -p /usr/local/lib/python3.6/site-packages \
	&& ln -s /usr/local/lib/python3.6/site-packages /usr/local/lib/python3.6/dist-packages

RUN apt-get update && \
	apt-get install -y \
		ca-certificates \
		iptables \
		btrfs-progs \
		e2fsprogs \
		iptables \
		openssl \
		xfsprogs \
		pigz \
		python3 \
		python3-six \
		python3-setuptools \
		python3-idna

COPY --from=builder /docker /usr/local/bin
COPY --from=builder /dind/dind /usr/local/bin/
COPY --from=builder /python /usr/local


RUN set -eux; \
	\
	dockerd --version; \
	docker --version; \
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
	addgroup --system dockremap; \
	adduser --system --ingroup dockremap dockremap; \
	echo 'dockremap:165536:65536' >> /etc/subuid; \
	echo 'dockremap:165536:65536' >> /etc/subgid

# https://github.com/docker-library/docker/pull/166
#   dockerd-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-generating TLS certificates
#   docker-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-setting DOCKER_TLS_VERIFY and DOCKER_CERT_PATH
# (For this to work, at least the "client" subdirectory of this path needs to be shared between the client and server containers via a volume, "docker cp", or other means of data sharing.)
ENV DOCKER_TLS_CERTDIR=/certs
# also, ensure the directory pre-exists and has wide enough permissions for "dockerd-entrypoint.sh" to create subdirectories, even when run in "rootless" mode
RUN mkdir /certs /certs/client && chmod 1777 /certs /certs/client
# (doing both /certs and /certs/client so that if Docker does a "copy-up" into a volume defined on /certs/client, it will "do the right thing" by default in a way that still works for rootless users)

# Clean up apt cache
RUN rm -rf /var/cache/apt/archives \
    && rm -rf /var/lib/apt/lists/*

COPY dockerd-entrypoint.sh /usr/local/bin/
COPY modprobe.sh /usr/local/bin/modprobe
COPY docker-entrypoint.sh /usr/local/bin/

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD []

