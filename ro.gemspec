## ro.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "ro"
  spec.version = "2.0.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "ro"
  spec.description = "description: ro kicks the ass"
  spec.license = "Ruby"

  spec.files =
["README.md",
 "Rakefile",
 "TODO",
 "TODO.md",
 "a.rb",
 "bak.gemspec",
 "bin",
 "bin/ro",
 "lib",
 "lib/ro",
 "lib/ro.rb",
 "lib/ro/_lib.rb",
 "lib/ro/asset.rb",
 "lib/ro/blankslate.rb",
 "lib/ro/cache.rb",
 "lib/ro/git.rb",
 "lib/ro/initializers",
 "lib/ro/initializers/env.rb",
 "lib/ro/initializers/tilt.rb",
 "lib/ro/lock.rb",
 "lib/ro/model.rb",
 "lib/ro/node",
 "lib/ro/node.rb",
 "lib/ro/node/list.rb",
 "lib/ro/pagination.rb",
 "lib/ro/root.rb",
 "lib/ro/slug.rb",
 "lib/ro/template.rb",
 "notes",
 "notes/ara.txt",
 "ro",
 "ro.gemspec",
 "ro/posts",
 "ro/posts/foo-bar",
 "ro/posts/foo-bar/assets",
 "ro/posts/foo-bar/attributes.yml",
 "ro/posts/foo-bar/body.erb"]

  spec.executables = ["ro"]
  
  spec.require_path = "lib"

  spec.test_files = nil

  
    spec.add_dependency(*["map", "~> 6.6", ">= 6.6.0"])
  
    spec.add_dependency(*["fattr", "~> 2.4", " >= 2.4.0"])
  
    spec.add_dependency(*["tilt", "~> 2.1", " >= 2.1.0"])
  
    spec.add_dependency(*["pygments.rb", "~> 2.3", " >= 2.3.1"])
  
    spec.add_dependency(*["coerce", "~> 0.0", " >= 0.0.8"])
  
    spec.add_dependency(*["stringex", "~> 2.8", " >= 2.8.5"])
  
    spec.add_dependency(*["systemu", "~> 2.6", " >= 2.6.5"])
  
    spec.add_dependency(*["nokogiri", "~> 1.14", " >= 1.14.2"])
  
    spec.add_dependency(*["main", "~> 6.3", " >= 6.3.0"])
  

  spec.extensions.push(*[])

  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/ro"
end
