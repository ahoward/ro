## NAME

ro - a read only data plane for yer web app

## TL;DR

- a current WIP
- keeps your content in git, as god intended.
  - organized in a logical disk structure that is easy to manage programatically
  - in a format that enables github's built-in editor to suffice as a content managing interface
- headless CMS that shit to your apps via the power of github pages + github workflows
  - you get a built in, free, http, https enabled (if you know you know (facebook og tags ;-/)) service to consume your content in any static or dynamic site builder
- huge images? just use git-lfs and git ;-)
- lots more docs coming soon...

an example fs layout.

<pre>
    ro
    ├── people
    │   ├── ara
    │   │   ├── assets
    │   │   │   ├── ara-glacier.jpg
    │   │   │   └── source
    │   │   │       └── a.rb
    │   │   ├── attributes.yml
    │   │   └── bio.md.erb
    │   └── noah
    │       └── attributes.yml
    └── posts
        ├── first-post
        │   ├── attributes.yml
        │   └── body.md
        └── second-post 
            ├── assets
            │   └── hero.jpg
            ├── attributes.yml
            └── body.md

</pre>
