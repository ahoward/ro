## ro.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "ro"
  spec.version = "4.2.0"
  spec.required_ruby_version = '>= 3.0'
  spec.platform = Gem::Platform::RUBY
  spec.summary = "all your content in github, as god intended"
  spec.description = "all your content in github, as god intended"
  spec.license = "Ruby"

  spec.files =
["Gemfile",
 "Gemfile.lock",
 "LICENSE",
 "README.md",
 "README.md.erb",
 "Rakefile",
 "bin",
 "bin/ro",
 "lib",
 "lib/ro",
 "lib/ro.rb",
 "lib/ro/_lib.rb",
 "lib/ro/asset.rb",
 "lib/ro/collection",
 "lib/ro/collection.rb",
 "lib/ro/collection/list.rb",
 "lib/ro/config.rb",
 "lib/ro/error.rb",
 "lib/ro/klass.rb",
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
 "public",
 "public/api",
 "public/api/ro",
 "public/api/ro/index-1.json",
 "public/api/ro/index.json",
 "public/api/ro/posts",
 "public/api/ro/posts/first_post",
 "public/api/ro/posts/first_post/index.json",
 "public/api/ro/posts/index-1.json",
 "public/api/ro/posts/index.json",
 "public/api/ro/posts/second_post",
 "public/api/ro/posts/second_post/index.json",
 "public/api/ro/posts/third_post",
 "public/api/ro/posts/third_post/index.json",
 "public/ro",
 "public/ro/posts",
 "public/ro/posts/first_post",
 "public/ro/posts/first_post/assets",
 "public/ro/posts/first_post/assets/foo",
 "public/ro/posts/first_post/assets/foo.jpg",
 "public/ro/posts/first_post/assets/foo/bar",
 "public/ro/posts/first_post/assets/foo/bar/baz.jpg",
 "public/ro/posts/first_post/assets/src",
 "public/ro/posts/first_post/assets/src/foo",
 "public/ro/posts/first_post/assets/src/foo/bar.rb",
 "public/ro/posts/first_post/attributes.yml",
 "public/ro/posts/first_post/blurb.erb.md",
 "public/ro/posts/first_post/body.md",
 "public/ro/posts/first_post/testing.txt",
 "public/ro/posts/second_post",
 "public/ro/posts/second_post/assets",
 "public/ro/posts/second_post/assets/foo",
 "public/ro/posts/second_post/assets/foo.jpg",
 "public/ro/posts/second_post/assets/foo/bar",
 "public/ro/posts/second_post/assets/foo/bar/baz.jpg",
 "public/ro/posts/second_post/assets/src",
 "public/ro/posts/second_post/assets/src/foo",
 "public/ro/posts/second_post/assets/src/foo/bar.rb",
 "public/ro/posts/second_post/attributes.yml",
 "public/ro/posts/second_post/blurb.erb.md",
 "public/ro/posts/second_post/body.md",
 "public/ro/posts/third_post",
 "public/ro/posts/third_post/assets",
 "public/ro/posts/third_post/assets/foo",
 "public/ro/posts/third_post/assets/foo.jpg",
 "public/ro/posts/third_post/assets/foo/bar",
 "public/ro/posts/third_post/assets/foo/bar/baz.jpg",
 "public/ro/posts/third_post/assets/src",
 "public/ro/posts/third_post/assets/src/foo",
 "public/ro/posts/third_post/assets/src/foo/bar.rb",
 "public/ro/posts/third_post/attributes.yml",
 "public/ro/posts/third_post/blurb.erb.md",
 "public/ro/posts/third_post/body.md",
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
