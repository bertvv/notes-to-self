+++
date = "2015-10-08T10:51:07+02:00"
draft = false
title = "Easily switch between Hyper-V and VirtualBox"
tags = ["windows", "virtualbox"]
categories = [ "System administration" ]

+++

Hyper-V and VirtualBox are two virtualization platforms that we both use in our system administration courses. Unfortunately, once Hyper-V is active, it won't coexist with other virtualization platforms. In this post, I discuss a method to work around this problem by setting up a custom boot entry for each platform.

<!--more-->

I manage two classrooms with 40 dual boot Windows Server and Linux (Fedora) computers. In our Windows Server course, the idea is to teach students to work with Hyper-V, but other courses taught in the same classroom usually use VirtualBox. Because I thought I couldn't install both, the easy solution was not to install VirtualBox. It's unconvenient, but students that need VirtualBox could boot into Fedora.

However, a few weeks ago, one of my students ran into a similar problem: he has Hyper-V installed on his laptop and also wanted to use VirtualBox for my Linux course. He then let me know that he solved the problem by disabling Hyper-V, something I didn't realize was possible. That made me wonder if there wasn't a solution that I could automate and deploy on all classroom computers.

Once I knew where to look, I found a few blog posts (a.o. [this one by Ben Armstrong](http://blogs.msdn.com/b/virtual_pc_guy/archive/2008/04/14/creating-a-no-hypervisor-boot-entry.aspx)) with instructions to create a new entry in the Windows Boot Manager. All good and well, but I'm not going to do this manually on 40 machines...

So I went a little further and wrote a PowerShell script that duplicates the current (single) boot entry, assigns suitable names to each, turns off Hyper-V in the copy, and made the copy the default one. This is the resulting script:

{{< highlight powershell >}}
# AddBootOptionNoHyperV.ps1
# Create a boot option with Hyper-V turned off

# Variables
$description = "Windows Server 2012 R2 -"

# Before doing anything, check if the boot option already exists
$already_added = bcdedit /enum | Select-String "VirtualBox"

If("$already_added" -ne "") {
    Write-Host "VirtualBox boot entry already added -- bailing out"
    Exit
}

# First, rename the current boot option to "[...] - Hyper V"
bcdedit /set "{current}" description "$description Hyper-V"

# Create a copy of the current boot option
bcdedit /copy "{current}" /d "$description VirtualBox"

# Get the name of the new boot option (assumed to be the last one
# listed by `bcdedit /enum`)
$vboxboot_guid = bcdedit /enum `
    | Select-String "description" -Context 3,0 `
    | % { $_.Context.PreContext[0] -replace '^identifier +'} `
    | Select -Last 1

# Turn off the hypervisor for the new boot entry
bcdedit /set "$vboxboot_guid" hypervisorlaunchtype off

# Make VirtualBox the default boot entry
bcdedit /default "$vboxboot_guid"
{{< /highlight >}}


Now, students that boot into Windows get the choice:

![Windows boot menu with options Hyper-V and VirtualBox](/img/bootmenu-hyperv-vbox.jpg)

Funny that I didn't learn about this stuff from my colleagues that have been teaching Windows Server for years... ;-)
