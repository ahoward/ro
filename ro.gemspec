## ro.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "ro"
  spec.version = "1.1.0"
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
 "bin",
 "bin/ro",
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
 "lib/ro/db/collection",
 "lib/ro/initializers",
 "lib/ro/initializers/env.rb",
 "lib/ro/initializers/tilt.rb",
 "lib/ro/node",
 "lib/ro/node.rb",
 "lib/ro/node/list.rb",
 "lib/ro/root.rb",
 "lib/ro/slug.rb",
 "lib/ro/template.rb",
 "notes",
 "notes/ara.txt",
 "ro",
 "ro.gemspec",
 "ro/people",
 "ro/people/ara",
 "ro/people/ara/assets",
 "ro/people/ara/assets/ara-glacier.jpg",
 "ro/people/ara/assets/source",
 "ro/people/ara/assets/source/a.rb",
 "ro/people/ara/attributes.yml",
 "ro/people/ara/bio.md.erb",
 "ro/people/noah",
 "ro/people/noah/attributes.yml",
 "ro/posts",
 "ro/posts/hello-world",
 "ro/posts/hello-world/attributes.yml",
 "ro/posts/hello-world/body.md",
 "ro/posts/second-awesome-post",
 "ro/posts/second-awesome-post/attributes.yml",
 "ro/posts/second-awesome-post/body.md"]

  spec.executables = ["ro"]
  
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
