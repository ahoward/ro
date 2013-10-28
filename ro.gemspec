## ro.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "ro"
  spec.version = "1.0.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "ro"
  spec.description = "description: ro kicks the ass"
  spec.license = "Same As Ruby's"

  spec.files =
[":",
 ":w",
 "=p",
 "README.md",
 "Rakefile",
 "lib",
 "lib/co",
 "lib/co/db.rb",
 "lib/co/node",
 "lib/co/node.rb",
 "lib/co/node/list.rb",
 "lib/co/util.rb",
 "lib/lib",
 "lib/ro",
 "lib/ro.rb",
 "lib/ro/blankslate.rb",
 "lib/ro/cache.rb",
 "lib/ro/db",
 "lib/ro/db.rb",
 "lib/ro/db/collection",
 "lib/ro/db/collection.rb",
 "lib/ro/initializers",
 "lib/ro/initializers/env.rb",
 "lib/ro/initializers/tilt.rb",
 "lib/ro/node",
 "lib/ro/node.rb",
 "lib/ro/node/list.rb",
 "lib/ro/root.rb",
 "lib/ro/slug.rb",
 "lib/ro/template.rb",
 "lib/ro/util.rb",
 "notes",
 "notes/ara.txt",
 "ro",
 "ro.gemspec",
 "ro/people",
 "ro/people/ara",
 "ro/people/ara/attributes.yml",
 "ro/posts",
 "ro/posts/foobar",
 "ro/posts/hello-world",
 "ro/posts/hello-world/attributes.yml"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = nil

  
    spec.add_dependency(*["map", " >= 6.5.1"])
  
    spec.add_dependency(*["fattr", " >= 2.2.1"])
  
    spec.add_dependency(*["tilt", " >= 1.4.1"])
  
    spec.add_dependency(*["pygments.rb", " >= 0.5.0"])
  
    spec.add_dependency(*["coerce", " >= 0.0.4"])
  
    spec.add_dependency(*["stringex", " >= 2.1.0"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/ro"
end
