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
 "TODO",
 "TODO.md",
 "bin",
 "bin/ro",
 "docs",
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
 "lib/ro/script.rb",
 "lib/ro/slug.rb",
 "lib/ro/template",
 "lib/ro/template.rb",
 "lib/ro/template/rouge_formatter.rb",
 "public",
 "public/api",
 "public/api/index",
 "public/api/index.json",
 "public/api/index/0.json",
 "public/api/posts",
 "public/api/posts/first-post",
 "public/api/posts/first-post/index.json",
 "public/api/posts/index",
 "public/api/posts/index.json",
 "public/api/posts/index/0.json",
 "public/api/posts/second-post",
 "public/api/posts/second-post/index.json",
 "public/ro",
 "public/ro/posts",
 "public/ro/posts/first-post",
 "public/ro/posts/first-post/assets",
 "public/ro/posts/first-post/assets/foo",
 "public/ro/posts/first-post/assets/foo.jpg",
 "public/ro/posts/first-post/assets/foo/bar",
 "public/ro/posts/first-post/assets/foo/bar/baz.jpg",
 "public/ro/posts/first-post/assets/image",
 "public/ro/posts/first-post/assets/src",
 "public/ro/posts/first-post/assets/src/foo",
 "public/ro/posts/first-post/assets/src/foo/bar.rb",
 "public/ro/posts/first-post/attributes.yml",
 "public/ro/posts/first-post/body.md",
 "public/ro/posts/first-post/foo.erb.md",
 "public/ro/posts/first-post/widget.erb",
 "public/ro/posts/second-post",
 "public/ro/posts/second-post/assets",
 "public/ro/posts/second-post/assets/foo",
 "public/ro/posts/second-post/assets/foo.jpg",
 "public/ro/posts/second-post/assets/foo/bar",
 "public/ro/posts/second-post/assets/foo/bar/baz.jpg",
 "public/ro/posts/second-post/assets/image",
 "public/ro/posts/second-post/assets/src",
 "public/ro/posts/second-post/assets/src/foo",
 "public/ro/posts/second-post/assets/src/foo/bar.rb",
 "public/ro/posts/second-post/attributes.yml",
 "public/ro/posts/second-post/body.erb",
 "public/ro/posts/second-post/widget.erb",
 "ro.gemspec",
 "src",
 "todo.rb"]

  spec.executables = ["ro"]
  
  spec.require_path = "lib"

  
    spec.add_dependency(*["map", "~> 6.6", ">= 6.6.0"])
  
    spec.add_dependency(*["kramdown", "~> 2.4", " >= 2.4.0"])
  
    spec.add_dependency(*["kramdown-parser-gfm", "~> 1.1", " >= 1.1.0"])
  
    spec.add_dependency(*["rouge", "~> 4.1", " >= 4.1.1"])
  
    spec.add_dependency(*["ak47", "~> 0.2"])
  

  spec.extensions.push(*[])

  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/ro"
end
