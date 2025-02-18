## ro.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "ro"
  spec.version = "4.3.1"
  spec.required_ruby_version = '>= 3.0'
  spec.platform = Gem::Platform::RUBY
  spec.summary = "all your content in github, as god intended"
  spec.description = "the worlds tiniest, bestest, most minmialist headless cms - powered by github\n\nro is a minimalist toolkit for managing heterogeneous collections of rich web\ncontent on github, and providing both programatic and api access to it with zero\nheavy lifting"
  spec.license = "Ruby"

  spec.files =
["Gemfile",
 "Gemfile.lock",
 "LICENSE",
 "README.md",
 "README.md.erb",
 "Rakefile",
 "a.rb",
 "bin",
 "bin/ro",
 "gem-details.oe",
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
 "lib/ro/html.rb",
 "lib/ro/html_safe.rb",
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
 "lib/ro/text.rb",
 "public",
 "public/api",
 "public/api/ro",
 "public/api/ro/index-1.json",
 "public/api/ro/index.json",
 "public/api/ro/people",
 "public/api/ro/people/ara-t-howard",
 "public/api/ro/people/ara-t-howard/index.json",
 "public/api/ro/people/index-1.json",
 "public/api/ro/people/index.json",
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
 "public/ro/people",
 "public/ro/people/ara-t-howard",
 "public/ro/posts",
 "public/ro/posts/first_post",
 "public/ro/posts/first_post/a.rb",
 "public/ro/posts/first_post/assets",
 "public/ro/posts/first_post/assets/foo",
 "public/ro/posts/first_post/assets/foo.jpg",
 "public/ro/posts/first_post/assets/foo/bar",
 "public/ro/posts/first_post/assets/foo/bar/baz.jpg",
 "public/ro/posts/first_post/assets/src",
 "public/ro/posts/first_post/assets/src/foo",
 "public/ro/posts/first_post/assets/src/foo/bar.rb",
 "public/ro/posts/first_post/attributes.yml",
 "public/ro/posts/first_post/b.html.rb",
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
 "ro.gemspec",
 "scripts",
 "scripts/speedtest.rb"]

  spec.executables = ["ro"]
  
  spec.require_path = "lib"

  
    spec.add_dependency(*["map", "~> 6.6", ">= 6.6.0"])
  
    spec.add_dependency(*["kramdown", "~> 2.4", " >= 2.4.0"])
  
    spec.add_dependency(*["kramdown-parser-gfm", "~> 1.1", " >= 1.1.0"])
  
    spec.add_dependency(*["rouge", "~> 4.1", " >= 4.1.1"])
  
    spec.add_dependency(*["front_matter_parser", "~> 1.0"])
  
    spec.add_dependency(*["rinku", "~> 2.0"])
  
    spec.add_dependency(*["image_size", "~> 3.4"])
  
    spec.add_dependency(*["nokogiri", "~> 1"])
  

  spec.extensions.push(*[])

  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/ro"
end
