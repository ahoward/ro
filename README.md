## NAME

ro (read only)

## DESCRIPTION

ro is a tiny tool for managing _tidy_ bundles of self-referiential web content in a super sane directory layout

```sh
~> tree ro/data

# ro/data
# └── posts
#     ├── first-post
#     │   ├── assets
#     │   │   ├── foo
#     │   │   │   └── bar
#     │   │   │       └── baz.jpg
#     │   │   ├── foo.jpg
#     │   │   └── src
#     │   │       └── foo
#     │   │           └── bar.rb
#     │   ├── attributes.yml
#     │   ├── blurb.erb.md
#     │   └── body.md
#     ├── second-post
#     │   ├── assets
#     │   │   ├── foo
#     │   │   │   └── bar
#     │   │   │       └── baz.jpg
#     │   │   ├── foo.jpg
#     │   │   └── src
#     │   │       └── foo
#     │   │           └── bar.rb
#     │   ├── attributes.yml
#     │   ├── blurb.erb.md
#     │   └── body.md
#     └── third-post
#         ├── assets
#         │   ├── foo
#         │   │   └── bar
#         │   │       └── baz.jpg
#         │   ├── foo.jpg
#         │   └── src
#         │       └── foo
#         │           └── bar.rb
#         ├── attributes.yml
#         ├── blurb.erb.md
#         └── body.md
```

to be compiled into a static headless CMS API

```sh
~> ro build

# ro.build: ro/data -> ro/public/ro
# ro.build: ro/public/ro/posts/first-post/assets/foo/bar/baz.jpg
# ro.build: ro/public/ro/posts/first-post/assets/foo.jpg
# ro.build: ro/public/ro/posts/first-post/assets/src/foo/bar.rb
# ro.build: ro/public/ro/posts/first-post/attributes.yml
# ro.build: ro/public/ro/posts/first-post/blurb.erb.md
# ro.build: ro/public/ro/posts/first-post/body.md
# ro.build: ro/public/ro/posts/second-post/assets/foo/bar/baz.jpg
# ro.build: ro/public/ro/posts/second-post/assets/foo.jpg
# ro.build: ro/public/ro/posts/second-post/assets/src/foo/bar.rb
# ro.build: ro/public/ro/posts/second-post/attributes.yml
# ro.build: ro/public/ro/posts/second-post/blurb.erb.md
# ro.build: ro/public/ro/posts/second-post/body.md
# ro.build: ro/public/ro/posts/third-post/assets/foo/bar/baz.jpg
# ro.build: ro/public/ro/posts/third-post/assets/foo.jpg
# ro.build: ro/public/ro/posts/third-post/assets/src/foo/bar.rb
# ro.build: ro/public/ro/posts/third-post/attributes.yml
# ro.build: ro/public/ro/posts/third-post/blurb.erb.md
# ro.build: ro/public/ro/posts/third-post/body.md
# ro.build: ro/public/ro/posts/first-post/index.json
# ro.build: ro/public/ro/posts/second-post/index.json
# ro.build: ro/public/ro/posts/third-post/index.json
# ro.build: ro/public/ro/posts/index/0.json
# ro.build: ro/public/ro/posts/index.json
# ro.build: ro/public/ro/index/0.json
# ro.build: ro/public/ro/index.json
# ro.build: ro/public/ro/index.html
# ro.build: ro/data -> ro/public/ro in 0.07s
```

and serving it automatically

static headless CMS

https://ahoward.github.io/ro/ro/posts/first-post/index.json

via GitHub Actions and GitHub Pages.

# WIP...

## TL;DR

```sh

  ~> ro build
  ~> ro build --watch
  ~> ro server
  ~> ro console

```
