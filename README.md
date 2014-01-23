NAME
----

ro


TL;DR
--------

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

  ro
    #=> all the content nodes

  ro.posts
    #=> all the post nodes

  ro.people                                 
    #=> all people nodes

  ro[:people]                               
    #=> same thing

  ro.people.ara                             
    #=> data for the person named 'ara'

  ro[:people][:ara]                         
    #=> same thing

  ro['people']['ara']                         
    #=> same thing

  ro.people.ara.first_name                  
    #=> give you *one* guess ;-) !

  ro.people.ara.url_for('ara-glacier.jpg')  
    #=> external timestamped  url for this asset

  ro.people.ara.source('a.rb')              
    #=> syntax highlighted source yo!

  ro.posts.find('second-awesome-post').body 
    #=> html-z yo

  ro.people.ara.related(:posts)             
    #=> all related posts

  ro.people.ara.related(:featured_posts)    
    #=> all featured posts
  

```

TRY
---

```bash

  ~ > git clone https://github.com/ahoward/ro.git
  ~ > cd ro
  ~> ./bin/ro console


  a:~/git/ahoward/ro $ ./bin/ro console
  Ro(./ro):001:0> ro.people
  => [people/ara, people/noah]

  Ro(./ro):002:0> ro.people.ara
  => people/ara

  Ro(./ro):003:0> ro.people.ara.first_name
  => "Ara"

  Ro(./ro):004:0> ro.people.ara.bio
  => "<ul>\n<li>one</li>\n<li>two</li>\n<li>three</li>\n</ul>\n\n<p>pretty syntax highlighting</p>\n<div class=\"highlight\"><pre>  <span class=\"vi\">@a</span> <span class=\"o\">=</span> <span class=\"mi\">42</span>\n</pre></div>\n<p>Ara</p>\n\n<p>/ro/people/ara/assets/ara-glacier.jpg?_=1382999368</p>\n"

  Ro(./ro):005:0> ro.people.ara.url_for('ara-glacier')
  => "/ro/people/ara/assets/ara-glacier.jpg?_=1382999368"

  Ro(./ro):006:0> ro.people.ara.related
  => [posts/hello-world, posts/second-awesome-post]

  Ro(./ro):007:0> ro.people.ara.related.posts
  => [posts/hello-world, posts/second-awesome-post]

  Ro(./ro):008:0> ro.people.ara.related(:featured_posts)
  => [posts/second-awesome-post]

```

DESCRIPTION
-----------

ro is library for managing your site's content in git, as god intended.

it features:

- super fast loading via a robust caching/promise strategy
- *all* teh templates supported via tilt (https://github.com/rtomayko/tilt)
- the awesomest markdown ever, with syntax highlighting and even erb evaluation
- an awesome command line tool for introspecting your data (./ro console)
- data driven relationships


ro is the *perfect* companion to a site built by a static site generator such
as middleman (http://middlemanapp.com/).  especially a middleman site with a
companion rails' application doing concurrent modifications of the site's
content... ;-)


INSTALL
-------

gem install ro


CONFIG
------

if you are using the url methods you'll need to make sure your application can
route to the assets.  by default ro assumes that the urls it generates are
routeable under '/ro' so it is up to you to make sure this works.

for a rails app this might mean writing a 'RoController' or, more simply, just
putting your ro data in ./public/ro.

for a middleman app this might mean putting your ro data in ./source/ro.

if you choose a non-standard approach you'll need to

```

  Ro.route = '/my-custom-route'


```

in all cases ro urls will be prefixed by the route, so be sure that this prefix
is either automatically, or manually, exposed.


DOCS
----

RTFC
