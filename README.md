TL;DR:
------

`ro` stands for `read only`, and it is the tiniest, best, headless cms.

it lets you keep all your content in github, as god intended.

it is one part cms, one part database, one part api, and one part magic.

if you used a headless cms, it's like that, before they existed, except way better, and free.

with `ro`, you can seperate your content from presentation, like a sane and decent human being.

> silent code whispers
> github's gentle, peaceful hush
> simplicity reigns

README
------

`ro` is has been in professional, production use for over a decade, powering
many, many websites built by http://dojo4.com, and others.

from static sites, to rails monoliths, to simple ruby sites, to javascript
sites built on next.js, `ro` is the portable, simple, future-proof content
system you always dreamed about then started to write but found out the web is
a mess.

with `ro`, your shit will be *clean*.

---

to grok `ro` it is best to start with an example of some real content,
for a real site.


```sh

  drawohara@drawohara.dev:ro[main] #=> tree public/ro/posts/almost-died-in-an-ice-cave/
  public/ro/posts/almost-died-in-an-ice-cave/
  ├── assets
  │   ├── image1.png
  │   ├── image2.png
  │   ├── image3.png
  │   ├── og.jpg
  │   └── purple-heart.jpg
  ├── attributes.yml
  └── body.md

```

in this example you can see a few things, regarding the layout of a `ro` directory:

- `ro` content often, but is not required, to live in `public`.  more on this below.

- the essential layout is

```ruby

    @root       = "ro"
    @collection = "posts"
    @id          = "almost-died-in-an-ice-cave"

    "#{ @root }/#{ @collection }/#{ @id }"

```

if you learn best by example, you can examine the `ro` directory of my own website here -> https://github.com/ahoward/drawohara.io/tree/main/public/ro

- several environment variables control how `ro` works, most notably

```ruby

  # this is the fs root of all ro content
  #

  Ro.root = ENV['RO_ROOT'] || './public/ro'

  # this is the url where ro content, especially images, will be expected to
  # live at when live

  Ro.url = ENV['RO_URL'] || '/ro'

```

more about this can be rtfm'd here -> https://github.com/ahoward/ro/blob/main/lib/ro.rb#L29-L55

because not having a repl sucks, `ro` has one.  you should too.

```sh

# fire up the KONSOULLLLL!

~> ro console ./public/ro/

```

```ruby

ro.posts.almost_died_in_an_ice_cave.attributes.keys #=>

  ["og", "body", "assets", "_meta"]

ro.posts.almost_died_in_an_ice_cave.attributes.og #=>

  {"image"=>{"url"=>"/ro/posts/almost-died-in-an-ice-cave/assets/og.jpg"},
   "title"=>"Almost Died In An Ice Cave",
   "description"=>"On April of 2024, I, along with 6 of my friends, dug for our lives to come out on the other side."}

ro.posts.almost_died_in_an_ice_cave.attributes.body.slice(0,420) #=>

  "<div class=\"ro markdown\">\n  <p><a href=\"#tl;dr;\">tl;dr;</a></p>\n\n<blockquote>\n  <p>in april, 2024, myself, and 6 brave men attempted to cross the harding\nicefield.</p>\n\n  <p>in celebration of <a href=\"https://en.wikipedia.org/wiki/Harding_Icefield#History\">yule kilcher’s 1968 crossing</a></p>\n\n  <p>midway through our trip, at the point of no return, we were beseiged by a storm of storms.</p>\n\n  <p>we dug shoulder to "

ro.posts.almost_died_in_an_ice_cave.assets.first #=>

  "public/ro/posts/almost-died-in-an-ice-cave/assets/image1.png"

ro.posts.almost_died_in_an_ice_cave.assets.first.url #=>

  "/ro/posts/almost-died-in-an-ice-cave/assets/image1.png"


```

__boom__ // **now we're cooking with gas!**

serveral things will be obvious to the non-ai enabled observer:

- every node has a hash of attributes
- 'file' attributes are *rendered* based on file type
- assets in rendered content are __url aware__

you can see the list of file types `ro` supports here -> https://github.com/ahoward/ro/blob/main/lib/ro/template.rb#L43-L63

if you can't build a website with just these...

🙊 [you've come to the wrong place!](https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExd2NpbmsxMHRxNnRsNjFzNWczN2JtejE5aXc0YXA3MHV3a3pwb3hodyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/vDlw1tKNwx40BGbWcQ/giphy.gif)

---
now, about that rendering process...

for any 'html-ish' type, links to relative assets, will be expanded such that
images will be resolved to thier final deployment destination.

eg. given __ro/posts/foo-bar/body.md__ containing the markdown

```markdown

[linky](./assets/report.pdf)

![alty](./assets/pretty.png)

```

you will end up with html that looks like so:

```html

<a href='/ro/posts/foo-bar/assets/report.pdf'>linky</a>

<img src='/ro/posts/foo-bar/assets/pretty.png'>alty</a>


```

---
__OH MAN THAT SUX I DO NOT WANT MY IMAGES STORED IN GH!!!!__

*sit down... breathe...*

and enable [git-lfs](https://git-lfs.com/)

it used to be fragile but, since everyone the in the world is now checking in massive jupyter notebooks it 'just works'

---
now, recall what we said about `public` and `RO_URL`?  by default, this is is `/ro`...

therefore, if we have:

`./public/ro/posts/foobar/...'

paths found under `public` are going to start with `/ro`...

> are you tracking yet?

also, if you do not host your `ro` directory under public (but why not?  it
*is* public content after all..), then you will need to set `RO_URL` to be the
ultimate destination of your image deployment.  this can be cloudinary, s3,
whatever.  it just needs to be the url prefix to whack in front of relative
image urls.

note - not only html has this 'expansion' applied, relative assets in your
attributes will be expanded too, at any depth.  eg. -> https://github.com/ahoward/ro/blob/main/lib/ro/methods.rb#L233-L260

this means code like this:

```yaml
# file: public/ro/posts/foo-bar/attributes.yml

og:
  image: ./assets/og.jpg
```

will 'just work'. of course, this assumes that 'public/ro/foo-bar/assets/og.jpg' exists!

the code is rather robust here, and is not a simple string bashing approach.

it's tight, and you can trust it.

---
a bit about markdown...

markdown is.  the web.  also AI, but i digress... if you aren't writing in
markdown, you are probably writing `perl`... (nothing wrong with that btw!)

but markdown has a lot of edge cases, not least of which syntax highlighting
and bs css to deal with.

`ro`, again, 'just works' here.

- it uses github flavored markdown (gfm), extracts front-matter and folds it
  into `attributes`, auto-links stuff (gfm does not), and inlines the css
  styles for speed and so you don't have to eff with the css to render src
  code all pretty.  see https://github.com/ahoward/ro/blob/main/lib/ro/template.rb#L117-L143

- you can set the gfm theme via the `RO_MD_THEME` ENV var. this supports
  anything [rouge](https://github.com/rouge-ruby/rouge) does.


---
> __I HATE RUBY!!!! RAWR__

whatever.  use javascript.  `ro` is also a 'static cms api builder`.

*WUT*?

it can compile your entire content db into a static api of js, designed to be
ultra, ultra, ultra easy to consume.  no stupid graphql thing, no bullsxxx
api_key, no vendor lock-in to prismic, dato, contentful, or some other
extorsionist regime., just a lil `fetch` and you are __GTG BRO!__

you don't even have to render the stuff, it's pre-rendered html in the api ready to `dangerouslySetInnerHTM`!

__(alsoCamelCaseMakeAPIHARDToReadWithEMPHASIS)__

you can see an example here -> https://github.com/ahoward/ro/tree/main/public/api/ro

i won't explain more now except to say that all you need to do to make a js
bundle is

```sh

~> ro build

```

and then look carefully, it makes it easy to 'grab everything stupid style' or
to paginate client side.  each collection has a `index.js` with everything, a
`index-$pageno.js` with details about the next page, iff any, and of course, it
produces an `index.json` file, complete with those gnarly *width* and *height*
numbers you need to *fight FUOC* and layout shift.

if you don't know what that means, probably use [wordpress](https://drawohara.io/dojo4/archive/irish-dance-and-wordpress-the-soul-destroyer/)

lil detail about that link^, it is from *10 years ago*, when dojo4 was still running, and running on `ro`.

---

one super comman pattern, is to add a build step to a github workflow, and
then publish the js api via gh-pages. see an example here:

https://github.com/ahoward/ro/blob/main/.github/workflows/gh-pages.yml

__WUT!?!?!___

- your content is in github
- you want to consume it in js
- add a build step to build the js api and deploy it via gh-pages
- consume that 'static cms api' via fetch

*free*, image ready, headless CMS.  yep.

... 🤯🤯🤯

---

finally, and, truly, this is possibly the *coup de grâce*, you can just
friggin use github as your CMS now!  why?  because the markdown previw on
gh... just works. 🤤

eg.  https://github.com/ahoward/ro/blob/main/public/ro/posts/almost-died-in-an-ice-cave/body.md

ADVANCED
---------

- include the public directory in your gh-pages, pull that shit through
  cloudinary/imgix/etc as the img src... responsive images, with client side
  processing.  zero work.

- use ro in your rails app/models with the `active_model` adapter.
  https://github.com/ahoward/ro/blob/main/lib/ro/model.rb , it supports
  pagination and all the things.  rails ready.

- explore built-in support for syntax highlighted source code.  just put a
  file in ./assets/src/a.rb and it 'just works'

- explore the api in the repl, you'll find POLS stuff like

```ruby

  ro.get('posts').get('almost-died-in-an-ice-cave')

  ro.get('posts/almost-died-in-an-ice-cave')

  ro.get('posts').get('almost-died-in-an-ice-cave').assets.first.img

  #=> {:format=>"png", :width=>1456, :height=>817}

```

DOCS
----
1) vibe it AI
2) RTFC

BORING SHIT
-----------

```sh

  ~> gem install ro

```

LICENSE
-------
https://github.com/LGUG2Z/komorebi-license

AI
--
suck it 🤖s!

REF
---
https://github.com/ahoward/ro
