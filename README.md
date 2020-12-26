# docker-molecule-docker

Dockerfile to create a container that runs Molecule with Docker containers. Can be used in CI to test Ansible roles.

# Usage

## Manual testing

Assuming that the source of the Ansible role is located at /home/user/my-role:

    docker run -d --privileged --name=molecule-test -v /home/user/my-role:/src/my-role blauwelucht/molecule-docker
	docker exec -it molecule-test bash
	
And then in the container:

    cd /src/my-role
    molecule test

## Concourse

```YAML
---
resources:
- name: git-src
  type: git
  source:
    uri: https://github.com/blauwe-lucht/ansible-role-docker-webapps
    branch: main

jobs:
- name: ansible-docker-webapps
  public: true
  serial: true
  plan:
  - get: git-src
    trigger: true
  - task: task-molecule
    privileged: true
    config:
      platform: linux
      image_resource:
        type: docker-image
        source:
          repository: blauwelucht/molecule-docker
          tag: 0.3
      inputs:
      - name: git-src
      run:
        dir: git-src
        path: sh
        args:
        - -c
        - |
          dockerd-entrypoint.sh &
          while ! docker info > /dev/null 2>&1
          do
              echo "Waiting for Docker to initialize..."
              sleep 2
          done
          molecule test
```
