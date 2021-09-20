---
date: 2021-09-21T00:46:21+02:00
title: "File Globbing and Hidden Files"
tags:
  - linux
categories:
  - "System administration"

---

A student asked me some time ago:

> When I execute `rm *.bak`, hidden files aren't removed. Don't they match the globbing pattern?

<!--more-->

Indeed, hidden files are ignored by the globbing pattern `*`. Frankly, I didn't know that at the time, so I looked it up in the Bash man-page [bash(1)](https://linux.die.net/man/1/bash). I found it under the heading "Pathname Expansion":

> When a pattern is used for pathname expansion, the character "." at the start of a name or immediately following a slash must be matched explicitly, unless the shell option dotglob is set.

Ah, interesting, so we can actually configure the behaviour with the shell option `dotglob`:

{{< highlight console >}}
$ shopt dotglob
dotglob         off
$ ls *.bak
=> hidden files will not be listed
$ shopt -e dotglob
$ ls *.bak
=> hidden files will be listed
{{< /highlight >}}
