## ro.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "ro"
  spec.version = "2.0.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "the worlds tiniest, bestest, most minmialist headless CMS - powered by GitHub"
  spec.description = "the worlds tiniest, bestest, most minmialist headless CMS - powered by GitHub"
  spec.license = "Ruby"

  spec.files =
["Gemfile",
 "Gemfile.lock",
 "LICENSE",
 "README.md",
 "Rakefile",
 "bin",
 "bin/ro",
 "lib",
 "lib/ro",
 "lib/ro.rb",
 "lib/ro/_lib.rb",
 "lib/ro/asset.rb",
 "lib/ro/collection.rb",
 "lib/ro/error.rb",
 "lib/ro/methods.rb",
 "lib/ro/model.rb",
 "lib/ro/node.rb",
 "lib/ro/pagination.rb",
 "lib/ro/path.rb",
 "lib/ro/root.rb",
 "lib/ro/script",
 "lib/ro/script.rb",
 "lib/ro/script/builder.rb",
 "lib/ro/script/console.rb",
 "lib/ro/script/server.rb",
 "lib/ro/slug.rb",
 "lib/ro/template",
 "lib/ro/template.rb",
 "lib/ro/template/rouge_formatter.rb",
 "ro",
 "ro.gemspec",
 "ro/config.ru",
 "ro/data",
 "ro/data/posts",
 "ro/data/posts/first-post",
 "ro/data/posts/first-post/assets",
 "ro/data/posts/first-post/assets/foo",
 "ro/data/posts/first-post/assets/foo.jpg",
 "ro/data/posts/first-post/assets/foo/bar",
 "ro/data/posts/first-post/assets/foo/bar/baz.jpg",
 "ro/data/posts/first-post/assets/src",
 "ro/data/posts/first-post/assets/src/foo",
 "ro/data/posts/first-post/assets/src/foo/bar.rb",
 "ro/data/posts/first-post/attributes.yml",
 "ro/data/posts/first-post/blurb.erb.md",
 "ro/data/posts/first-post/body.md",
 "ro/data/posts/second-post",
 "ro/data/posts/second-post/assets",
 "ro/data/posts/second-post/assets/foo",
 "ro/data/posts/second-post/assets/foo.jpg",
 "ro/data/posts/second-post/assets/foo/bar",
 "ro/data/posts/second-post/assets/foo/bar/baz.jpg",
 "ro/data/posts/second-post/assets/src",
 "ro/data/posts/second-post/assets/src/foo",
 "ro/data/posts/second-post/assets/src/foo/bar.rb",
 "ro/data/posts/second-post/attributes.yml",
 "ro/data/posts/second-post/blurb.erb.md",
 "ro/data/posts/second-post/body.md",
 "ro/data/posts/third-post",
 "ro/data/posts/third-post/assets",
 "ro/data/posts/third-post/assets/foo",
 "ro/data/posts/third-post/assets/foo.jpg",
 "ro/data/posts/third-post/assets/foo/bar",
 "ro/data/posts/third-post/assets/foo/bar/baz.jpg",
 "ro/data/posts/third-post/assets/src",
 "ro/data/posts/third-post/assets/src/foo",
 "ro/data/posts/third-post/assets/src/foo/bar.rb",
 "ro/data/posts/third-post/attributes.yml",
 "ro/data/posts/third-post/blurb.erb.md",
 "ro/data/posts/third-post/body.md",
 "ro/public",
 "ro/public/index.html",
 "ro/public/ro",
 "ro/public/ro/index",
 "ro/public/ro/index.html",
 "ro/public/ro/index.json",
 "ro/public/ro/index/0.json",
 "ro/public/ro/posts",
 "ro/public/ro/posts/first-post",
 "ro/public/ro/posts/first-post/assets",
 "ro/public/ro/posts/first-post/assets/foo",
 "ro/public/ro/posts/first-post/assets/foo.jpg",
 "ro/public/ro/posts/first-post/assets/foo/bar",
 "ro/public/ro/posts/first-post/assets/foo/bar/baz.jpg",
 "ro/public/ro/posts/first-post/assets/src",
 "ro/public/ro/posts/first-post/assets/src/foo",
 "ro/public/ro/posts/first-post/assets/src/foo/bar.rb",
 "ro/public/ro/posts/first-post/attributes.yml",
 "ro/public/ro/posts/first-post/blurb.erb.md",
 "ro/public/ro/posts/first-post/body.md",
 "ro/public/ro/posts/first-post/index.json",
 "ro/public/ro/posts/index",
 "ro/public/ro/posts/index.json",
 "ro/public/ro/posts/index/0.json",
 "ro/public/ro/posts/second-post",
 "ro/public/ro/posts/second-post/assets",
 "ro/public/ro/posts/second-post/assets/foo",
 "ro/public/ro/posts/second-post/assets/foo.jpg",
 "ro/public/ro/posts/second-post/assets/foo/bar",
 "ro/public/ro/posts/second-post/assets/foo/bar/baz.jpg",
 "ro/public/ro/posts/second-post/assets/src",
 "ro/public/ro/posts/second-post/assets/src/foo",
 "ro/public/ro/posts/second-post/assets/src/foo/bar.rb",
 "ro/public/ro/posts/second-post/attributes.yml",
 "ro/public/ro/posts/second-post/blurb.erb.md",
 "ro/public/ro/posts/second-post/body.md",
 "ro/public/ro/posts/second-post/index.json",
 "ro/public/ro/posts/third-post",
 "ro/public/ro/posts/third-post/assets",
 "ro/public/ro/posts/third-post/assets/foo",
 "ro/public/ro/posts/third-post/assets/foo.jpg",
 "ro/public/ro/posts/third-post/assets/foo/bar",
 "ro/public/ro/posts/third-post/assets/foo/bar/baz.jpg",
 "ro/public/ro/posts/third-post/assets/src",
 "ro/public/ro/posts/third-post/assets/src/foo",
 "ro/public/ro/posts/third-post/assets/src/foo/bar.rb",
 "ro/public/ro/posts/third-post/attributes.yml",
 "ro/public/ro/posts/third-post/blurb.erb.md",
 "ro/public/ro/posts/third-post/body.md",
 "ro/public/ro/posts/third-post/index.json"]

  spec.executables = ["ro"]
  
  spec.require_path = "lib"

  
    spec.add_dependency(*["map", "~> 6.6", ">= 6.6.0"])
  
    spec.add_dependency(*["kramdown", "~> 2.4", " >= 2.4.0"])
  
    spec.add_dependency(*["kramdown-parser-gfm", "~> 1.1", " >= 1.1.0"])
  
    spec.add_dependency(*["rouge", "~> 4.1", " >= 4.1.1"])
  
    spec.add_dependency(*["ak47", "~> 0.2"])
  
    spec.add_dependency(*["webrick", "~> 1.8.1"])
  

  spec.extensions.push(*[])

  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/ro"
end
