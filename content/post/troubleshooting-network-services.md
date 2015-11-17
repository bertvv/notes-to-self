+++
categories = [ "System administration" ]
date = "2015-10-18T10:31:00+02:00"
tags = ["linux", "troubleshooting"]
title = "Troubleshooting network services"
draft = "true"

+++

This post discusses troubleshooting a network service running on a Linux system. Actually, teaching troubleshooting in detail is quite impossible. The insight you need to drill down on the root cause of a problem comes only with bitter experience and the problems you can encounter are too diverse and dependent on how your infrastructure is set up. However, what *is* possible is to provide you with a general framework and apply this to some common problems that arise when setting up a network service (e.g. Apache, BIND, Samba, ...) on a Linux machine.

<!--more-->

## Preliminaries

Before we get into it, we make a few assumptions:

- You have basic knowledge about networking: the TCP/IP protocol stack, IP addresses, port numbers, etc.
- The commands given below are specifically for recent versions of Fedora (≥15) and CentOS/RHEL (≥7) that have systemd as the init system.


