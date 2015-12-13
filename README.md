# Notes to self

This repository contains the source code of my blog, hosted on <https://bertvv.github.io/notes-to-self>. If you want me to write about a specific subject within the topics covered (Linux, CentOS, Ansible, LaTeX, ...), [open an issue](https://github.com/bertvv/notes-to-self/issues)!

## Setup

The `public/` directory contains the generated site, as it is published on Github Pages. It is set up as a [`git-worktree(1)`](https://git-scm.com/docs/git-worktree) for the `gh-pages` branch.

The `themes/` directory is ignored, as it is a separate Git repository (a [fork](https://github.com/bertvv/greyshade) of the [greyshade](https://github.com/cxfksword/greyshade) theme).

The other directories are the Hugo "source code" of the site.

## Cheat sheet

Useful commands

### Workflow

**New post**

```ShellSession
$ hugo new post/some-title.md
$ hugo server --buildDrafts --watch  # In a separate console
$ vi content/post/some-title.md
$ hugo undraft content/post/some-title.md
```

**Publish on Github Pages**

Run script `./publish.sh TITLE`, which does the following:

- Test whether `hugo server` is running (it should not!)
- Generate the site with command `hugo`
- Push changes in both `master` and `gh-pages` to Github

### Tricks

**Read more link**

```
<!--more-->
```

**Source code**

```
{{< highlight LANGUAGE>}}
source code
{{< /highlight >}}
```

For a list of supported languages, see <http://pygments.org/languages/>

