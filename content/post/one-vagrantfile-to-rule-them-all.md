+++
date = "2015-10-05T16:59:14+02:00"
draft = false
title = "One Vagrantfile to rule them all"
categories = [ "System administration" ]
tags = [ "vagrant" ]
+++

Writing Vagrantfiles is tedious, especially when you're setting up a multi-VM environment. Typically, people will copy/paste code blocks that define hosts, but that becomes unwieldy. However, a Vagrantfile is "just" Ruby, so can't we simplify things a bit using the power of the language? Turns out, we can! Read below to find how you can reduce setting up a multi-VM Vagrant environment to writing a simple YAML file.

<!--more-->

## Simplifying multi-VM setups

A typical Vagrantfile has separate blocks of code for each host (see e.g. [this StackOverflow discussion](https://stackoverflow.com/questions/24072916/multi-vm-in-one-vagrantfile-could-i-set-different-memory-size-for-each-of-them)). When the complexity of your environment grows, this becomes harder and harder to maintain. The [Vagrant documentation](https://docs.vagrantup.com/v2/vagrantfile/tips.html) states that you can simplify by introducing loops in your Vagrantfile, but then you have the problem of how to manage differences in the properties of each VM. A nice solution to this is to define a Hash at the beginning of the Vagrantfile with the properties and apply them for each host (see e.g. [this example](https://gist.github.com/dlutzy/2469037)).

## A universal Vagrantfile (sort of)

I developed a Vagrantfile (for the full source, see the end of this post or my Github project [ansible-skeleton](https://github.com/bertvv/ansible-skeleton)) where the parts that have to be changed, i.e. properties of individual machines, are stored in a separate YAML file. The Vagrantfile will parse the YAML file and apply the settings to each specified VM. A simple example to get started:

{{< highlight yaml >}}
# vagrant_hosts.yml
- name: box001
  ip: 192.168.56.10
- name: box002
{{< /highlight >}}

This will create a Vagrant environment with two VMs, `box001` and `box002`. Each will get a private network interface. For `box001` a fixed IP address (192.168.56.10) is assigned, `box002` will get one via DHCP.

The Vagrantfile will parse the YAML and convert it to a Ruby data structure, specifically a list of Hashes:

{{< highlight ruby >}}
hosts = YAML.load_file('vagrant_hosts.yml')
{{< /highlight >}}

This is the main loop of the script that iterates over the `hosts`:

{{< highlight ruby "linenos=inline" >}}
  hosts.each do |host|
    config.vm.define host['name'] do |node|
      node.vm.box = host['box'] ||= DEFAULT_BASE_BOX
      node.vm.box_url = host['box_url'] ||= DEFAULT_BASE_BOX_URL

      node.vm.hostname = host['name']
      node.vm.network :private_network, network_options(host)
      custom_synced_folders(node.vm, host)

      node.vm.provider :virtualbox do |vb|
        vb.name = host['name']
        vb.customize ['modifyvm', :id, '--groups', PROJECT_NAME]
      end
    end
  end
{{< /highlight >}}

In line 2, a new VM is defined with the name `host['name']`. In the example above, that is `box001` in the first iteration and `box002` in te next one.

Then (line 3-4) the a base box is specified. If you don't explicitly define one in `vagrant_hosts.yml`, a default one will be assigned (specified at the beginning of the Vagrantfile). The same goes for the URL where to download the base box from if it isn't available yet on your machine.

On line 7, a private network interface is added. The second argument, `network_options(host)` is a function call that reads out specific options for the network card, e.g. network mask, MAC address, etc. I'm not going into this in detail, but the code can be found at the end of this post.

It's possible to specify [synced folders](https://docs.vagrantup.com/v2/synced-folders/index.html). Line 8 calls the method that sets these up. An example of how these can be set up in `vagrant_hosts.yml`:

{{< highlight yaml >}}
- name: box002
  ip: 192.168.56.11
  synced_folders:
    - src: test
      dest: /tmp/test
    - src: www
      dest: /var/www/html
      options:
        :create: true
        :owner: root
        :group: root
        :mount_options: ['dmode=0755', 'fmode=0644']
{{< /highlight >}}

This gives `box002` two synced folders. One is mounted under `/tmp/test`, the other under `/var/www/html`. The second synced folder has a few options, e.g that the owner and group should be `root` (instead of `vagrant`). The colons in front of the option names (`:create`, `:group`, etc.) are mandatory here.

Finally, lines 10-13 apply a few VirtualBox-specific settings. The VM name in VirtualBox is set to the host name (`box002`) instead of the standard name assigned by Vagrant (e.g. `projectdir_box002_1443709007553_58669`). Also, the VMs will be grouped together in the VirtualBox GUI.

## Provisioning

Once the VM is configured and booted, Vagrant allows you to run a provisioning script that finalizes the configuration of the VM. I use Ansible for this, and let every host read the same master playbook (see the "[Playbooks Best Practices](https://docs.ansible.com/ansible/playbooks_best_practices.html)" section of the [Ansible Documentation](https://docs.ansible.com/ansible/)).

However, most of my students are using Windows which is [not supported by Ansible](https://docs.ansible.com/ansible/intro_installation.html#control-machine-requirements). In this case, I work around this problem by installing Ansible on the VM and invoking it locally instead of from the host system. The Vagrantfile detects the host operating system and invokes the appropriate provisioning code:

{{< highlight ruby "linenos=inline" >}}
def is_windows
  RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
end

def provision_ansible(config)
  if is_windows
    # Run shell script that installs and runs Ansible locallty (on Windows)
    config.vm.provision "shell" do |sh|
      sh.path = "scripts/playbook-win.sh"
    end
  else
    # Run Ansible from host machine (on Mac/Linux).
    config.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/site.yml"
      ansible.sudo = true
    end
  end
end
{{< /highlight >}}

I'm not discussing the provisioning script `scripts/playbook-win.sh` in this blog post. It's based on the work of [Kawsar Saiyeed](https://github.com/KSid/windows-vagrant-ansible) and [Jeff Geerling](https://github.com/geerlingguy/JJG-Ansible-Windows) and my version can be found on my Github project [ansible-skeleton](https://github.com/bertvv/ansible-skeleton).

## Conclusion

And that's about it! After setting the default base box name and download URL in the Vagrantfile, you don't need to touch the Vagrantfile anymore. Adding a VM is just a couple of lines of YAML. See the [source code for `vagrant_hosts.yml`](https://github.com/bertvv/ansible-skeleton/blob/master/vagrant_hosts.yml) for an overview of all supported settings.

If you have suggestions for improvements, let me know! Pull requests on the [project](https://github.com/bertvv/ansible-skeleton) are also more than welcome.

## The complete Vagrantfile

You can find the complete Vagrantfile below. The latest version is available in my [Ansible skeleton](https://github.com/bertvv/ansible-skeleton) project on Github.

{{< highlight ruby >}}
# -*- mode: ruby -*-
# vi: ft=ruby :

require 'rbconfig'
require 'yaml'

# Set your default base box here
DEFAULT_BASE_BOX = 'centos71-nocm'
DEFAULT_BASE_BOX_URL = 'https://tinfbo2.hogent.be/pub/vm/centos71-nocm-1.0.16.box'

#
# No changes needed below this point
#

VAGRANTFILE_API_VERSION = '2'
PROJECT_NAME = '/' + File.basename(Dir.getwd)

hosts = YAML.load_file('vagrant_hosts.yml')

# {{{ Helper functions

def is_windows
  RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
end

def provision_ansible(config)
  if is_windows
    # Provisioning configuration for shell script.
    config.vm.provision "shell" do |sh|
      sh.path = "scripts/playbook-win.sh"
    end
  else
    # Provisioning configuration for Ansible (for Mac/Linux hosts).
    config.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/site.yml"
      ansible.sudo = true
    end
  end
end

# Set options for the network interface configuration. All values are
# optional, and can include:
# - ip (default = DHCP)
# - netmask (default value = 255.255.255.0
# - mac
# - auto_config (if false, Vagrant will not configure this network interface
# - intnet (if true, an internal network adapter will be created instead of a
#   host-only adapter)
def network_options(host)
  options = {}

  if host.has_key?('ip')
    options[:ip] = host['ip']
    options[:netmask] = host['netmask'] ||= '255.255.255.0'
  else
    options[:type] = 'dhcp'
  end

  if host.has_key?('mac')
    options[:mac] = host['mac'].gsub(/[-:]/, '')
  end
  if host.has_key?('auto_config')
    options[:auto_config] = host['auto_config']
  end
  if host.has_key?('intnet') && host['intnet']
    options[:virtualbox__intnet] = true
  end

  options
end

def custom_synced_folders(vm, host)
  if host.has_key?('synced_folders')
    folders = host['synced_folders']

    folders.each do |folder|
      vm.synced_folder folder['src'], folder['dest'], folder['options']
    end
  end
end

# }}}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  hosts.each do |host|
    config.vm.define host['name'] do |node|
      node.vm.box = host['box'] ||= DEFAULT_BASE_BOX
      node.vm.box_url = host['box_url'] ||= DEFAULT_BASE_BOX_URL

      node.vm.hostname = host['name']
      node.vm.network :private_network, network_options(host)
      custom_synced_folders(node.vm, host)

      node.vm.provider :virtualbox do |vb|
        vb.name = host['name']
        vb.customize ['modifyvm', :id, '--groups', PROJECT_NAME]
      end
    end
  end
  provision_ansible(config)
end

{{< /highlight  >}}
