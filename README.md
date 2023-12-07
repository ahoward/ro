# NAME

`ro`

# SYNOPSIS

The K.I.S.S, tiny, headless C.M.S your O.C.D. mother told you to use.

# TL;DR;

`ro` is the world's tiniest, simplest, zero-config, and headless CMS. It
depends on nothing but GitHub itself for the storage, management, and delivery
of rich web content and assets.

## Storage

`ro` keeps your structured web content in a super sane structure, that keeps
assets close to its related content, allows for structured data to be kept
along side markdown/html content, and which supports source code as a first
class citizen.

For example, given:

```sh
    ~> tree ro/data

    # ro/data
    # └── posts
    #     ├── first-post
    #     │   ├── attributes.yml
    #     │   └── body.md
    #     │   ├── blurb.erb.md
    #     │   ├── assets
    #     │   │   ├── foo.jpg
```

`ro` will provide an interface logically consistent with:

```ruby
    node.attributes        #=> any/all the data loaded from 'attributes.yml'
    node.attributes.body   #=> an HTML representation of 'body.md' 
    node.attributes.blurb  #=> an HTML representation of 'blurb.md' 
    node.attributes.assets #=> list of assets with url and path info
```

To learn more, clone this repo, `bundle install`, and fire up a console to
check play with this idea:

eg: [given this node](https://github.com/ahoward/ro/tree/main/ro/data/posts/first-post)

```ruby
    ~> ro console

    ro[./ro/data]:001:0> ro.collections.posts.first_post.title
    => "First Post"

    ro[./ro/data]:002:0> ro.collections.posts.first_post.assets.first.url
    => "/ro/posts/first-post/assets/foo.jpg"

    ro[./ro/data]:003:0> ro.collections.posts.first_post.body.slice(0,42)
    => "<div class='ro markdown'>\n  <ul>\n  <li>one"
```


## Management

Managing `ro` is as simple as using the built-in GitHub Markdown editor.  The
file system layout, which supports relative asset urls, means the built-in
editor preview renders just fine.  Of course, you are free to manage content
programatically as well.  Either way, updates to the the content will result
in an automated API build of a static API which is then deployed to GitHub
Pages.

This is made possible by certain design decisions `ro` has made, specifically
allowing assets/ to be stored and rendered relative to their parent content.

Of course, you have all the power of `git` so other methods of managing the
content are available, programtic, locally in vs-code, etc.  You have lots of
simply options, none of which require drivers or databases, and all of which
provide perfect history over your valuable web content and assets.

A word on managing assets, if you plan to have many large images, you probably
want to enable GitLFS on your content repository, `ro` plays perfectly with
it.


## Delivery

Delivery of `ro` content, to remote clients, is via http+json.  To output your
content as json, you simply need to run

```sh
    ~>  ro build

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
    # ro.build: ro/data -> ro/public/ro in 0.08s
```

During the build, assets are expanded to be the full URL of the final
deployment destination.  This is done via the RO_URL environment variable, and
automatically with a pre-build GitHub Action that will deploy your content via
GitHub Pages. See
https://github.com/ahoward/ro/blob/main/.github/workflows/gh-pages.yml#L55 for
more details.

You can view sample output from this Action, deployed to GH Pages here: https://ahoward.github.io/ro



# USAGE

#### WRITE-ME // #TODO

## API // Javascript

#### WRITE-ME // #TODO

## CLI

#### WRITE-ME // #TODO

## Programatic // Ruby

#### WRITE-ME // #TODO

## Via Repository

#### WRITE-ME // #TODO

- note on http vs https
