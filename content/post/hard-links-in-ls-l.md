+++
date = "2015-10-18T09:46:19+02:00"
draft = false
title = "The number of hard links in ‘ls -l’"

+++

When you execute the command `ls -l` in UNIX, you get detailed information about files: permissions, file size, date of last modification, etc. A while ago, I got a question from one of my students who wondered what the second column meant. According to the documentation, it's the "number of hard links," but what does that actually mean? Let's get to the bottom of this.

<!--more-->

One of my students, Tom, wrote:

> I created a directory `test2` containing a file, 3 scripts and another directory `test` containing the same file and scripts. I don't know whether this is relevant, but I mention it anyway. I created the directory `test2` by copying another directory and copying it within itself (I was playing with `cp`).
>
> To get back to the number of hard links: when I executed `ls -l`, I saw the number 3 next to directory `test2`. I looked into hard links and noticed that all hard links have the same inode. So I thought, let's find all hard links of `test2` with the `find / -inum ...` command. However, I only received 1 value: `/home/tom/test2` while I expected at least 2 or 3.

So, Tom doubts whether the number in the second column is in fact the number of hard links. The documentation (`info ls`) at least confirms this:

```
'-l'
'--format=long'
'--format=verbose'
     In addition to the name of each file, print the file type, file
     mode bits, number of hard links, owner name, group name, size, and
     timestamp (*note Formatting file timestamps::), normally the
     modification time.  Print question marks for information that
     cannot be determined.
```

Let's get to the bottom of this...

## Hard links between files

The example below shows that for ordinary files, the second column really is the number of hard links:

{{< highlight bash >}}
$ touch orig
$ ls -li
total 0
1706858 -rw-rw-r--. 1 bert bert 0 Nov  5 21:55 orig
$ ln orig link
$ ls -li
1706858 -rw-rw-r--. 2 bert bert 0 Nov  5 21:55 link
1706858 -rw-rw-r--. 2 bert bert 0 Nov  5 21:55 orig
$ find . -inum 1706858
./orig
./link
{{< /highlight >}}

When creating the file `orig`, the number of hard links was 1. I also added the option `-i` to show the [inode number](https://en.wikipedia.org/wiki/Inode). This number uniquely identifies a file. I then created a hard link from the original file. As you can see, both files now have the same inode number and the number of hard links is incremented. Searching on inode number finds both files.

Copying with `cp`, as Tom did in his example, creates a *new* file with the same contents as the original. That means that the inode numbers are also different! Changes in one file will not be registered in the other one. The same goes for *symbolic links*, in fact:

{{< highlight bash >}}
$ ln -s orig symb
$ ls -il
total 0
1706858 -rw-rw-r--. 2 bert bert 0 Nov  5 21:55 link
1706858 -rw-rw-r--. 2 bert bert 0 Nov  5 21:55 orig
1707044 lrwxrwxrwx. 1 bert bert 4 Nov  5 22:38 symb -> orig
{{< /highlight >}}

## Directories

Now, hard links between directories don't exist, so the interpretation of the term "number of hard links" is a bit different than with ordinary files. In this case, the number represents how many other directories ‘link to’ it. Specifically, that means the parent directory and all directories immediately below. A new directory starts at "2", i.e. a link from ‘itself’ and one from the parent directory. The number will increment when you create subdirectories, but not when you create new files or symbolic links.

Take a look at the example below, and try it for yourself. Take your time, I'll wait...

{{< highlight bash >}}
$ ls -l
total 0
$ mkdir a b
$ ls -l
total 8
drwxrwxr-x. 2 bert bert 4096 Nov  5 21:26 a
drwxrwxr-x. 2 bert bert 4096 Nov  5 21:26 b
$ mkdir a/c
$ ls -l
total 8
drwxrwxr-x. 3 bert bert 4096 Nov  5 21:27 a
drwxrwxr-x. 2 bert bert 4096 Nov  5 21:26 b
$ mkdir a/d
$ ls -l
total 8
drwxrwxr-x. 4 bert bert 4096 Nov  5 21:27 a
drwxrwxr-x. 2 bert bert 4096 Nov  5 21:26 b
$ touch a/f
$ ls -l
total 8
drwxrwxr-x. 4 bert bert 4096 Nov  5 21:27 a
drwxrwxr-x. 2 bert bert 4096 Nov  5 21:26 b
$ ln -rs b a/e
$ ls -l
total 8
drwxrwxr-x. 4 bert bert 4096 Nov  5 21:48 a
drwxrwxr-x. 2 bert bert 4096 Nov  5 21:26 b
$ tree -F
.
|-- a/
|   |-- c/
|   |-- d/
|   |-- e -> ../b/
|   `-- f
`-- b/
{{< /highlight >}}

Every time I created a new subdirectory, the number of hard links incremented, but not when creating a file or symbolic link, even to a directory!

As mentioned earlier, creating hard links from directories doesn't work:

{{< highlight bash >}}
$ ln a c
ln: ‘a’: hard link not allowed for directory
{{< /highlight >}}

So when Tom was using find to search for a directory `test2` based on its inode number, it could necessarily only find it once.

To finish off, let's look at a corner case, specifically the root directory (`/`) of the file system. On my laptop:

{{< highlight bash >}}
$ ls -l /
total 64
lrwxrwxrwx.   1 root root     7 Sep 27 16:37 bin -> usr/bin
dr-xr-xr-x.   5 root root  3072 Oct 29 09:03 boot
drwxr-xr-x.  22 root root  3700 Nov  5 18:33 dev
drwxr-xr-x. 149 root root 12288 Nov  5 18:33 etc
drwxr-xr-x.   4 root root  4096 Jul  8 10:56 home
lrwxrwxrwx.   1 root root     7 Sep 27 16:37 lib -> usr/lib
lrwxrwxrwx.   1 root root     9 Sep 27 16:37 lib64 -> usr/lib64
drwx------.   2 root root 16384 Jun 27 19:09 lost+found
drwxr-xr-x.   2 root root  4096 Jul  8 10:56 media
drwxr-xr-x.   3 root root  4096 Jul  8 10:56 mnt
drwxr-xr-x.   4 root root  4096 Sep 27 22:05 opt
dr-xr-xr-x. 263 root root     0 Nov  4 10:28 proc
dr-xr-x---.   5 root root  4096 Nov  3 02:32 root
drwxr-xr-x.  37 root root  1120 Nov  5 21:46 run
lrwxrwxrwx.   1 root root     8 Sep 27 16:37 sbin -> usr/sbin
drwxr-xr-x.   2 root root  4096 Jul  8 10:56 srv
dr-xr-xr-x.  13 root root     0 Nov  4 09:28 sys
drwxrwxrwt.  16 root root   420 Nov  5 21:46 tmp
drwxr-xr-x.  13 root root  4096 Sep 27 16:37 usr
drwxr-xr-x.  21 root root  4096 Sep 27 16:39 var
$ ls -ld /
dr-xr-xr-x. 18 root root 4096 Nov  4 09:29 /
{{< /highlight >}}

As you can see in the last line, the number of hard links of `/` is 18. When you count the number of subdirectories directly below `/` (*not* counting symbolic links like `/sbin -> /usr/sbin`), you get 16. Adding the directory's "own" hard link, you would expect the final number to be 17 because `/` is at the top of the directory hierarchy, right? But let's try this:

{{< highlight bash >}}
$ cd ..; pwd
/
$ cd ..; pwd
/
$ cd ..; pwd
/
...
{{< /highlight >}}

Turtles all the way up! So apparently, the root directory is its own parent directory! And consequently, the number 18 is right after all...

Thank you, Tom, for the interesting question!

*(I wrote and published this post elsewhere at first, but I'm consolidating everything that is worth preserving on this site.)*
