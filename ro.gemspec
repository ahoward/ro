## ro.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "ro"
  spec.version = "2.0.0"
  spec.required_ruby_version = '>= 3.0'
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
 "ro.bak/data",
 "ro.bak/data/posts",
 "ro.bak/data/posts/first-post",
 "ro.bak/data/posts/first-post/assets",
 "ro.bak/data/posts/first-post/assets/foo",
 "ro.bak/data/posts/first-post/assets/foo.jpg",
 "ro.bak/data/posts/first-post/assets/foo/bar",
 "ro.bak/data/posts/first-post/assets/foo/bar/baz.jpg",
 "ro.bak/data/posts/first-post/assets/src",
 "ro.bak/data/posts/first-post/assets/src/foo",
 "ro.bak/data/posts/first-post/assets/src/foo/bar.rb",
 "ro.bak/data/posts/first-post/attributes.yml",
 "ro.bak/data/posts/first-post/blurb.erb.md",
 "ro.bak/data/posts/first-post/body.md",
 "ro.bak/data/posts/second-post",
 "ro.bak/data/posts/second-post/assets",
 "ro.bak/data/posts/second-post/assets/foo",
 "ro.bak/data/posts/second-post/assets/foo.jpg",
 "ro.bak/data/posts/second-post/assets/foo/bar",
 "ro.bak/data/posts/second-post/assets/foo/bar/baz.jpg",
 "ro.bak/data/posts/second-post/assets/src",
 "ro.bak/data/posts/second-post/assets/src/foo",
 "ro.bak/data/posts/second-post/assets/src/foo/bar.rb",
 "ro.bak/data/posts/second-post/attributes.yml",
 "ro.bak/data/posts/second-post/blurb.erb.md",
 "ro.bak/data/posts/second-post/body.md",
 "ro.bak/data/posts/third-post",
 "ro.bak/data/posts/third-post/assets",
 "ro.bak/data/posts/third-post/assets/foo",
 "ro.bak/data/posts/third-post/assets/foo.jpg",
 "ro.bak/data/posts/third-post/assets/foo/bar",
 "ro.bak/data/posts/third-post/assets/foo/bar/baz.jpg",
 "ro.bak/data/posts/third-post/assets/src",
 "ro.bak/data/posts/third-post/assets/src/foo",
 "ro.bak/data/posts/third-post/assets/src/foo/bar.rb",
 "ro.bak/data/posts/third-post/attributes.yml",
 "ro.bak/data/posts/third-post/blurb.erb.md",
 "ro.bak/data/posts/third-post/body.md",
 "ro.bak/public",
 "ro.bak/public/index.html",
 "ro.bak/public/ro",
 "ro.bak/public/ro/index",
 "ro.bak/public/ro/index.html",
 "ro.bak/public/ro/index.json",
 "ro.bak/public/ro/index/0.json",
 "ro.bak/public/ro/posts",
 "ro.bak/public/ro/posts/first-post",
 "ro.bak/public/ro/posts/first-post/assets",
 "ro.bak/public/ro/posts/first-post/assets/foo",
 "ro.bak/public/ro/posts/first-post/assets/foo.jpg",
 "ro.bak/public/ro/posts/first-post/assets/foo/bar",
 "ro.bak/public/ro/posts/first-post/assets/foo/bar/baz.jpg",
 "ro.bak/public/ro/posts/first-post/assets/src",
 "ro.bak/public/ro/posts/first-post/assets/src/foo",
 "ro.bak/public/ro/posts/first-post/assets/src/foo/bar.rb",
 "ro.bak/public/ro/posts/first-post/attributes.yml",
 "ro.bak/public/ro/posts/first-post/blurb.erb.md",
 "ro.bak/public/ro/posts/first-post/body.md",
 "ro.bak/public/ro/posts/first-post/index.json",
 "ro.bak/public/ro/posts/index",
 "ro.bak/public/ro/posts/index.json",
 "ro.bak/public/ro/posts/index/0.json",
 "ro.bak/public/ro/posts/second-post",
 "ro.bak/public/ro/posts/second-post/assets",
 "ro.bak/public/ro/posts/second-post/assets/foo",
 "ro.bak/public/ro/posts/second-post/assets/foo.jpg",
 "ro.bak/public/ro/posts/second-post/assets/foo/bar",
 "ro.bak/public/ro/posts/second-post/assets/foo/bar/baz.jpg",
 "ro.bak/public/ro/posts/second-post/assets/src",
 "ro.bak/public/ro/posts/second-post/assets/src/foo",
 "ro.bak/public/ro/posts/second-post/assets/src/foo/bar.rb",
 "ro.bak/public/ro/posts/second-post/attributes.yml",
 "ro.bak/public/ro/posts/second-post/blurb.erb.md",
 "ro.bak/public/ro/posts/second-post/body.md",
 "ro.bak/public/ro/posts/second-post/index.json",
 "ro.bak/public/ro/posts/third-post",
 "ro.bak/public/ro/posts/third-post/assets",
 "ro.bak/public/ro/posts/third-post/assets/foo",
 "ro.bak/public/ro/posts/third-post/assets/foo.jpg",
 "ro.bak/public/ro/posts/third-post/assets/foo/bar",
 "ro.bak/public/ro/posts/third-post/assets/foo/bar/baz.jpg",
 "ro.bak/public/ro/posts/third-post/assets/src",
 "ro.bak/public/ro/posts/third-post/assets/src/foo",
 "ro.bak/public/ro/posts/third-post/assets/src/foo/bar.rb",
 "ro.bak/public/ro/posts/third-post/attributes.yml",
 "ro.bak/public/ro/posts/third-post/blurb.erb.md",
 "ro.bak/public/ro/posts/third-post/body.md",
 "ro.bak/public/ro/posts/third-post/index.json",
 "ro.gemspec"]

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
