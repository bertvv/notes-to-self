---
title: "Troubleshooting Netbeans Slow Startup Time"
date: 2014-12-16T12:00:00+01:00
categories:
  - "Networking"
  - "Development"
tags:
  - linux
  - dns
  - networking
---

This weekend, I installed NetBeans 8.0.2 and was dismayed that it consistently) took 1' 23" to start. Here's how I found out what went wrong. Spoiler: it’s a [DNS problem](http://www.krisbuytaert.be/blog/).

This post was first [published on Medium](https://medium.com/@bertvanvreckem/troubleshooting-netbeans-slow-startup-time-b34bb78c5d6d), but I moved it over here.

<!--more-->

I tweeted about my predicament:

{{< tweet 543874939405996033 >}}

The splash screen is shown and sits there, no notification that anything is wrong, no error message.

I immediately got a few reactions, a.o. from @GeertjanW (Oracle product manager on the NetBeans team) who was kind enough to offer his help figuring out what was going on.

{{< tweet 543887082629124096>}}

He made a few suggestions, a.o. printing out a thread dump during startup. This revealed some interesting results:

```text
[...]
"AWT-EventQueue-0" #20 prio=6 os_prio=0 tid=0x00007f3728102800 nid=0x19f3 waiting for monitor entry [0x00007f377fbf9000]
   java.lang.Thread.State: BLOCKED (on object monitor)
       at java.net.InetAddress.getLocalHost(InetAddress.java:1465)
       - waiting to lock <0x00000000c080a788> (a java.lang.Object)
       at sun.font.FcFontConfiguration.getFcInfoFile(FcFontConfiguration.java:352)
       at sun.font.FcFontConfiguration.readFcInfo(FcFontConfiguration.java:425)
       at sun.font.FcFontConfiguration.init(FcFontConfiguration.java:94)
[...]
"main" #15 prio=5 os_prio=0 tid=0x00007f37a4612000 nid=0x19ee waiting for monitor entry [0x00007f3784dce000]
   java.lang.Thread.State: BLOCKED (on object monitor)
       at java.net.InetAddress.getLocalHost(InetAddress.java:1465)
       - waiting to lock <0x00000000c080a788> (a java.lang.Object)
       at org.eclipse.osgi.framework.internal.core.UniversalUniqueIdentifier.getIPAddress(UniversalUniqueIdentifier.java:146)
       at org.eclipse.osgi.framework.internal.core.UniversalUniqueIdentifier.computeNodeAddress(UniversalUniqueIdentifier.java:113)
       at org.eclipse.osgi.framework.internal.core.UniversalUniqueIdentifier.<clinit>(UniversalUniqueIdentifier.java:35)
[...]
```

Basically, it appears the method getLocalHost() was slowing everything down. I fired up [Wireshark](https://www.wireshark.org/) to see if some network traffic was generated. Indeed, I saw eight DNS lookups on my laptop’s host name (four A and four AAAA lookups).

Of course, this does not resolve. On my home network, my router is the DNS server and only replies after about fifteen seconds if a host name is not found. The `getLocalHost()` method, when it doesn’t receive a response within five seconds, will repeat the request a few times. In total, the method, tested with the following Java program, takes twenty seconds when DNS requests time out…

{{< codeblock "TestLocalHost.java" "java" "https://gist.github.com/bertvv/7082bd1c0fbaf8b5ac8c#file-testlocalhost-java" "TestLocalHost.java">}}
public class TestLocalHost {
  public static void main(String[] args) throws Exception {
    System.out.println(java.net.InetAddress.getLocalHost());
  }
}
{{< /codeblock >}}

*At work*, the DNS server immediately replies when a hostname does not resolve, so the startup time of NetBeans is considerably faster (about three seconds).

So, apparently, `getLocalHost()` is called a few (four?) times during startup, resulting in 1' 23" total…

The solution/workaround is to add an entry for my hostname to `/etc/hosts`.

And [@KrisBuytaert](https://twitter.com/KrisBuytaert/) is [right once again](https://krisbuytaert.be/blog/)…
