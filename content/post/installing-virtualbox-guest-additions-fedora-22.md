+++
categories = [ "System administration" ]
date = "2015-10-08T19:06:48+02:00"
tags = ["fedora", "linux", "virtualbox"]
title = "Installing VirtualBox Guest Additions in Fedora 22"

+++

VirtualBox Guest additions are a set of drivers that you can install on virtual machines to enable a few cool features: a scaling desktop in the VM, shared clipboard, shared folders, etc. This post discusses how to install these in Fedora 22.

<!--more-->

You can easily find other HOWTO's that describe the installation process. For example, I like the one on [If Not True Then False](http://www.if-not-true-then-false.com/2010/install-virtualbox-guest-additions-on-fedora-centos-red-hat-rhel/). That one covers quite a few versions of Fedora and CentOS, which may be confusing for beginning Linux users. This post focuses on recent Fedora versions, specifically Fedora 22 and newer, where `yum` is replaced by `dnf` as the package management tool.

## Installation procedure

Open a terminal (click Activities and type "Terminal") and execute the following commands:

1. First, update the kernel:

    {{< highlight bash >}}$ sudo dnf upgrade kernel*{{< /highlight >}}

2. Reboot the VM when a new kernel version was installed.
3. Install some packages needed for the installation:

    {{< highlight bash >}}$ sudo dnf install dkms kernel-headers kernel-devel{{< /highlight >}}

4. Open the "Devices" menu in the VM window and select "Insert Guest Additions CD Image..."

    ![Devices > Insert Guest Additions CD Image](/img/vboxadditions-instert-cd.png)

5. Click "Run" in the Autorun dialog box.

    ![Autorun dialog box](/img/vboxadditions-autorun.png)

6. A terminal window will open that informs you of the installation process. Look for `[  OK  ]` and `[FAILED]` in the output. If you followed the instructions, you should only see `[  OK  ]`s.

    ![Guest Additions Installation](/img/vboxadditions-installation.png)

7. Log out (the menu in the top right corner of the screen, click your user name and choose Log out) and back in.

That's it!
