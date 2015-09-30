+++
date = "2015-09-30T21:32:37+02:00"
draft = true
title = "Easily switch between Hyper-V and VirtualBox"
tags = ["windows", "virtualbox"]
categories = [ "System administration" ]

+++

I manage two classrooms with 40 dual boot Windows Server and Linux (Fedora) computers. In our Windows Server course, the idea is to teach students to work with Hyper-V, but other courses taught in the same classroom usually use VirtualBox. Unfortunately, Hyper-V and VirtualBox (or any other virtualization platform for that matter) don't coexist. The easy solution was not to install VirtualBox. It's unconvenient, but students that need VirtualBox could boot into Fedora.

However, a few weeks ago, one of my students ran into a similar problem: he has Hyper-V installed on his laptop and also wanted to use VirtualBox for my Linux course. He then let me know that he solved the problem by disabling Hyper-V, something I didn't realize was possible. That made me wonder if there wasn't a solution that I could automate and deploy on all classroom computers.

Once I knew where to look, I found a few blog posts (a.o. [this one by Ben Armstrong](http://blogs.msdn.com/b/virtual_pc_guy/archive/2008/04/14/creating-a-no-hypervisor-boot-entry.aspx)) with instructions to create a new entry in the Windows Boot Manager. All good and well, but I'm not going to do this manually on 40 machines...

So I went a little further and wrote a PowerShell script that duplicates the boot entry, assigns suitable names to each, turns off Hyper-V in the copy, and made the copy the default one. Now, students that boot into Windows get the choice:

![Windows boot menu with options Hyper-V and VirtualBox](/img/bootmenu-hyperv-vbox.jpg)

This is the resulting script:

{{< highlight powershell >}}
# TODO:
{{< /highlight >}}
