# Setup

```ShellSession
$ hugo new site notes-to-self
$ cd notes-to-self
$ hugo new about.md

```

# Workflow

## New post

```ShellSession
$ hugo new post/some-title.md
$ vi content/post/some-title.md
$ hugo undraft post/some-title.md
```

Watch progress with

```ShellSession
$ hugo server --buildDrafts --watch
```

## Publish on Github Pages

`hugo shell` should not be running when you do this:

```ShellSession
$ hugo
$ git add . && git commit -m "blah" && git push
$ git subtree push --prefix=public git@github.com:bertvv/notes-to-self.git gh-pages
```

See <https://gohugo.io/tutorials/github-pages-blog/>

# Themes

<https://github.com/spf13/hugoThemes/>

- herring-cove (disqus werkt meteen)
- liquorice - wit, zwarte titelbar
- pixyll - wit, witte titelbar
- hurock - zwarte sidebar
- persona - zwarte sidebar die je kan wegklikken, vrij veel mogelijkheden daar
- material-design - grote titel, menu klapt links weg, artikels in een grid (3 cols)
