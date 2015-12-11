+++
categories = ["Configuration Management"]
date = "2015-12-11T20:49:16+01:00"
tags = ["linux", "ansible", "travis-ci", "centos", "docker", "test-driven-infrastructure"]
title = "Testing Ansible roles with Travis-CI, Part 1: CentOS"

+++

In this first post on testing Ansible roles with Travis-CI, we'll discuss how you can apply a test playbook on CentOS.

<!--more-->

I've known about [Travis-CI](https://travis-ci.org/) as a test platform for a while now, but haven't tried it out until a few days ago. It is mainly used for running tests on applications, but it has seen use for infrastructure testing as well. For example, Jeff Geerling already [wrote about testing Ansible roles](https://servercheck.in/blog/testing-ansible-roles-travis-ci-github) using Travis-CI.

There's a lot to like about Travis-CI: it's free for open source projects and it integrates nicely with Github so that on every push and submitted pull request a test run is triggered. During a test run, a VM is booted and a script called `.travis.yml` is executed. This contains the necessary steps to configure the system, install dependencies and run the actual test code. Jeff Geerling's method of testing Ansible roles consists of installing Ansible and then running a test playbook locally that applies the role to the VM.

Now, the reason that I haven't been working with Travis-CI before (apart from lack of time), is that the VM that's being created is Ubuntu-based. I'm mostly working with CentOS, however, and all [my Ansible roles](https://galaxy.ansible.com/detail#/user/8834) only run on CentOS (at least for now). So as far as I knew, Travis-CI was not suitable for my needs.

Earlier this week, I ran into a [question on StackOverflow](https://stackoverflow.com/questions/29453017/build-project-on-centos-using-travis) on this very subject. One of the replies stated that it is possible to run CentOS on Travis-CI using Docker. Interesting...

Docker is another technology I haven'd played with before, so two learning opportunities in one go! I'm not going to delve into getting started with Docker, [you can find that elsewhere](https://docs.docker.com/engine/userguide/basics/).

## Setting up a CentOS Docker container

In this section, we're going to set up a simple test for my own [Apache role](https://galaxy.ansible.com/detail#/role/3047).
The first step is to create a Docker container for CentOS with all dependencies installed. After a few attempts, I settled for the following Dockerfile:

{{< highlight bash>}}
FROM centos:7
# Install systemd -- See https://hub.docker.com/_/centos/
RUN yum -y swap -- remove fakesystemd -- install systemd systemd-libs
RUN yum -y update; yum clean all; \
(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*; \
rm -f /etc/systemd/system/*.wants/*; \
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*; \
rm -f /lib/systemd/system/anaconda.target.wants/*;
# Install Ansible
RUN yum -y install epel-release
RUN yum -y install git ansible sudo
RUN yum clean all
# Disable requiretty
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers
# Install Ansible inventory file
RUN echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts
COPY requirements.yml /etc/ansible/requirements.yml
COPY test.yml /etc/ansible/test.yml
RUN ansible-galaxy install -r /etc/ansible/requirements.yml
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]
{{</ highlight >}}

This is based a.o. on the [guidelines](https://hub.docker.com/_/centos/) for the `centos:7` image found on Docker Hub. By default, systemd is not available inside the container, so the code above installs it, albeit in a limited form. After that, Ansible is installed and a basic inventory file is generated. Finally, the test code is pushed to the container, consisting of two files. The first one is `requirements.yml` that [specifies the dependencies](https://docs.ansible.com/ansible/galaxy.html#advanced-control-over-role-requirements-files), including the role under test. These are installed using `ansible-galaxy`. The second one is the test playbook `test.yml` that will apply the role under test to the container.

{{< highlight Yaml>}}
# /etc/ansible/requirements.yml
---
- src: bertvv.httpd

# /etc/ansible/test.yml
---
- hosts: all
  roles:
    - bertvv.httpd
{{</ highlight >}}

## Running the Ansible test on Travis-CI

The next step is to configure Travis-CI with a `.travis.yml` file. In this stage, I ran into another problem w.r.t. systemd. After building the container, I succeeded in running `ansible-playbook`, but the role failed when the service was started:

```
[...A number of succeeding tasks, a.o. installation of httpd...]

TASK: [bertvv.httpd | Ensure Apache is always running] ************************
failed: [localhost] => {"failed": true}
msg: no service or tool found for: httpd
```

Theres's a [bug report](https://bugzilla.redhat.com/show_bug.cgi?id=1033604) relating to this issue. Dan Walsh [navigates around this problem](https://developerblog.redhat.com/2014/05/05/running-systemd-within-docker-container/) by enabling the service after installation and then running a new container that will start the service at boot time. For our purposes, this is not a feasible solution. Another caveat is that the container should run in privileged mode in order to make systemd work.

Finally, I got to the following `.travis.yml` file:

{{< highlight Yaml>}}
sudo: required

services:
  - docker

before_install:
  # Fetch base image and build new container
  - sudo docker pull centos:7
  - sudo docker build --rm=true --tag=travispoc .

script:
  # Run container in detached state
  - sudo docker run --detach --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro travispoc /usr/lib/systemd/systemd > /tmp/container_id
  # Check syntax of ansible playbook
  - sudo docker exec "$(cat /tmp/container_id)" ansible-playbook /etc/ansible/test.yml --syntax-check
  # Run ansible playbook
  - sudo docker exec "$(cat /tmp/container_id)" ansible-playbook /etc/ansible/test.yml
  # Clean up
  - sudo docker stop "$(cat /tmp/container_id)"

notifications:
  email: false
{{</ highlight >}}

See the result of the build process on the [Travis-CI status page](https://travis-ci.org/bertvv/travispoc/builds/96155750). This configuration pulls down the base image `centos:7` and builds the custom container with Ansible installed. The custom container is then run in privileged mode and detached. The command yields an ID that is written to a temporary file. After that, the test playbook is executed, once with the `--syntax-check` option, and once without (actually applying the role to the container).

## Limitations

In the end, a container is -intentionally- not a full VM, so it does have its limitations. As discussed before, systemd is not available out-of-the-box. Basic services that you expect to be present, like ssh and firewalld aren't installed by default. Another big issue is SELinux. Since this is a kernel extension, I suspect it would interact with the host system. The host system in this case is Travis-CI's Ubuntu box that runs the tests, and that certainly won't have SELinux enabled. I haven't looked into this, but I suspect that in this setting, SELinux will not work inside the container. Please let me know in the comments if I'm wrong! Anyway, my roles usually assume SELinux is running, so I suspect it won't be possible to test these on Travis-CI... In those cases, a solution based on full virtualization like KVM, VirtualBox, etc. is probably more suitable.

## Conclusion

In this post, I discussed a proof of concept for testing Ansible roles on CentOS using Travis-CI. The code can be found on <https://github.com/bertvv/travispoc> and is tagged `centos` (See the [tags page](https://github.com/bertvv/travispoc/tags)). Although there are some limitations (SELinux being a notable one), Travis-CI is usable as a testing platform in this setting.

There's room for improvement, of course. It would be interesting to postpone pushing the test code to the container until after the build. This would allow us to always use the same base image with Ansible installed instead of rebuilding it at each test run. One approach could be to start the container with the folder containing the test code mounted inside using the `--volume` option. I probably did things in a suboptimal way, because I'm still new to both Travis-CI and Docker, so other suggestions are also welcome! You can leave a comment below, create an issue on the Github project or send me a pull request.

In a next blog post, we'll extend this solution for running tests on multiple platforms.
