+++
categories = ["Configuration Management"]
date = "2015-12-13T16:00:32+01:00"
draft = "true"
tags = ["linux", "ansible", "travis-ci", "centos", "docker", "test-driven-infrastructure"]
title = "Testing Ansible roles with Travis-CI, Part 2: Multi-platform tests"

+++

In the [previous post on testing Ansible roles with Travis-CI](https://bertvv.github.io/notes-to-self/2015/12/11/testing-ansible-roles-with-travis-ci-part-1-centos), I introduced a method to run playbooks on CentOS using Docker. In this post, we take this one step further and show how you can run multi-platform tests of Ansible roles.

<!--more-->

As a proof of concept, I'll continue with the example of [part one](https://bertvv.github.io/notes-to-self/2015/12/11/testing-ansible-roles-with-travis-ci-part-1-centos): Apache, the hello world of configuration management. My own [Apache role](https://galaxy.ansible.com/detail#/role/3047) was written only for EL/CentOS (for now), so it's not suitable. Therefore I thought of giving [Jeff Geerling](https://twitter.com/geerlingguy)'s [Apache role](https://galaxy.ansible.com/detail#/role/428) a try. We'll set up a test environment with two target platforms: Ubuntu and CentOS.

## Setting up the Docker containers

The test code is structured as follows (relative to the root of the Git project):

```
.
├── tests
│   ├── Dockerfile.centos
│   ├── Dockerfile.ubuntu
│   └── test.yml
└── .travis.yml
```

The Dockerfile for CentOS is the same as in [part one](https://bertvv.github.io/notes-to-self/2015/12/11/testing-ansible-roles-with-travis-ci-part-1-centos), so I won't repeat it here. The one for the Ubuntu container follows below. It is a bit simpler because we don't have to install systemd.

```
# Dockerfile.ubuntu
FROM ubuntu:14.04
# Install Ansible
RUN apt-get install -y software-properties-common git
RUN apt-add-repository -y ppa:ansible/ansible
RUN apt-get update
RUN apt-get install -y ansible
# Install Ansible inventory file
RUN echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts
```

## Running the tests

This is the test playbook:

{{< highlight Yaml >}}
# test.yml
---
- hosts: all
  vars:
    apache_listen_port_ssl: 443
    apache_create_vhosts: true
    apache_vhosts_filename: "vhosts.conf"
    apache_vhosts:
      - servername: "example.com"
        documentroot: "/var/www/vhosts/example_com"
  roles:
    - role_under_test
{{< /highlight >}}

It will be run on both the Ubuntu and the CentOS container. The `.travis.yml` file becomes:


{{< highlight Yaml >}}
# .travis.yml
---
sudo: required
env:
  - >
    container_id=$(mktemp)
    distribution=centos
    version=7
    init=/usr/lib/systemd/systemd
    run_opts="--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
  - >
    container_id=$(mktemp)
    distribution=ubuntu
    version=14.04
    init=/sbin/init
    run_opts=""

services:
  - docker

before_install:
  - sudo apt-get update
  # Pull container
  - sudo docker pull ${distribution}:${version}
  # Customize container
  - sudo docker build --rm=true --file=tests/Dockerfile.${distribution} --tag=${distribution}:ansible tests

script:
    # Run container in detached state
  - sudo docker run --detach --volume="${PWD}":/etc/ansible/roles/role_under_test:ro ${run_opts} ${distribution}:ansible "${init}" > "${container_id}"

    # Syntax check
  - sudo docker exec --tty "$(cat ${container_id})" env TERM=xterm ansible-playbook /etc/ansible/roles/role_under_test/tests/test.yml --syntax-check
    # Test role
  - sudo docker exec --tty "$(cat ${container_id})" env TERM=xterm ansible-playbook /etc/ansible/roles/role_under_test/tests/test.yml
    # Idempotence test
  - >
    sudo docker exec "$(cat ${container_id})" ansible-playbook /etc/ansible/roles/role_under_test/tests/test.yml
    | grep -q 'changed=0.*failed=0'
    && (echo 'Idempotence test: pass' && exit 0)
    || (echo 'Idempotence test: fail' && exit 1)

    # Clean up
  - sudo docker stop "$(cat ${container_id})"

notifications:
  email: false
{{< /highlight >}}

With the `env:` section, Travis-CI allows you to define different environments in which the tests should be run. We have defined two here, one for Ubuntu and one for CentOS. All the differences between the two cases are stored in environment variables that are available when the tests are run.

The `before_install:` section pulls the base container image for the desired Linux distribution and version (`centos:7` and `ubuntu:14.04`) and a custom image is built using the appropriate Dockerfile.

In the `script:` section, the container is started, and the current directory is mounted inside the container under `/etc/ansible/roles/role_under_test`. Next, the test playbook is run with the `--syntax-check` option. The command line options `--tty` and `env TERM=xterm` enable coloured output. Then, the test playbook is executed twice. The first time, the role is applied and Apache is installed with the configuration specified by the role variables. The second time is an idempotence test: applying the role a second time should not result in any changes. In the case a change *did* happen or if a task failed, an appropriate error message is printed and the process will abort.

An example of the build output can be found [here](https://travis-ci.org/bertvv/ansible-role-apache/builds/96604650) (for as long as Travis keeps the build logs).

![Build status on the Travis-CI website. The output for the tests on CentOS and Ubuntu are shown separately (#9.1 and #9.2 respectively).](/img/travis-build-status.png)

## Future work

There is still room for improvement, of course.

Tests for other platforms supported by the role can be added easily by creating a Dockerfile and adding a line to the `env:` section of `.travis.yml`.

The containers with Ansible installed are built on-the-fly, but they are always the same. Consequently, they can be reused for most, if not all, other roles you might want to run tests on. If you publish the containers on [Docker Hub](https://hub.docker.com/) (with any other customizations you may want), you can pull them from there and skip the build step.

What also could be added is black box system/acceptance tests from the host system (i.e. the Travis-CI VM), e.g. trying to access the website that runs on the container with `curl`, checking the TLS certificate, etc. This is left as an exercise to the upstream maintainer... ;-)

## Conclusion

The complete code for this test setup was [submitted upstream as a pull request](https://github.com/geerlingguy/ansible-role-apache/pull/60). As you will see in the commit history, there were quite a few hiccups as I was still getting familiar with the tools, and I made a few mistakes that I'll attribute to the fact that I continued working on this until rather late at night... ;-)

Testing Ansible roles on Travis-CI becomes a very compelling proposition, given the flexibility Docker containers provide. Whether it is suitable in *all* situations remains an open question. Most of my roles, for example, assume SELinux is running, but this is probably not available in a container set up within the Ubuntu VM provided by Travis-CI. If you know more about this, I would be interested to hear from you!

I finish this post with a shout-out to Valeriy Solovyov who (as far as I can tell) pioniered this method of testing Ansible roles. The code for his [Apache role](https://github.com/weldpua2008/ansible-apache), and [this discussion on Stack Overflow](https://stackoverflow.com/questions/32535195/how-to-run-tests-on-centos-7-with-travis-ci) are the only sources I could find on this, however.
