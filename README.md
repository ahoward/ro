NAME
----

ro


TL
--------

```bash

  ~ > tree ./ro

```

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
        ├── foobar
        ├── hello-world
        │   ├── attributes.yml
        │   └── body.md
        └── second-awesome-post
            ├── attributes.yml
            └── body.md

</pre>


```ruby

  ro.people   #=> all people nodes
  ro[:people] #=> same thing

  ro.people.ara     #=> data for the person named 'ara'
  ro[:people][:ara] #=> same thing


  ro.people.ara.first_name #=> give you *one* guess ;-) !

  ro.people.ara.url_for('ara-glacier.jpg') #=> external, timestamped,  url for this asset

  ro.people.ara.source('a.rb')             #=> syntax highlighted source yo!
  

```


DESCRIPTION
-----------

ro is library for managing your site's content in git, as god intended.

it features:

- super fast loading via a robust caching/promise strategy
- all templates supported via tilt (https://github.com/rtomayko/tilt)
- the awesomest markdown ever, with syntax highlighting and even erb evaluation
- an awesome command line tool for introspecting your data (./ro console)


INSTALL
-------

gem install ro (coming soon)


DOCS
----

RTFC
