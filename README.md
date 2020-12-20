# docker-molecule-docker

Dockerfile to create a container that runs Molecule with Docker containers. Can be used in CI to test Ansible roles.

# Usage

## Manual testing

Assuming that the source of the Ansible role is located at /home/user/my-role:

    docker run --rm --privileged -it -v /home/user/my-role:/src/my-role blauwelucht/molecule-docker bash
	
And then in the container:

    /usr/bin/dockerd -H unix:///var/run/docker.sock &
    cd /src/my-role
    molecule test

## Concourse

TODO
