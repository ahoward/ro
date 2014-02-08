## ro.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "ro"
  spec.version = "1.4.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "ro"
  spec.description = "description: ro kicks the ass"
  spec.license = "Same As Ruby's"

  spec.files =
["README.md",
 "Rakefile",
 "TODO.md",
 "bin/ro",
 "lib/ro.rb",
 "lib/ro/blankslate.rb",
 "lib/ro/cache.rb",
 "lib/ro/git.rb",
 "lib/ro/initializers/env.rb",
 "lib/ro/initializers/tilt.rb",
 "lib/ro/lock.rb",
 "lib/ro/model.rb",
 "lib/ro/node.rb",
 "lib/ro/node/list.rb",
 "lib/ro/pagination.rb",
 "lib/ro/root.rb",
 "lib/ro/slug.rb",
 "lib/ro/template.rb",
 "notes/ara.txt",
 "ro.gemspec"]

  spec.executables = ["ro"]
  
  spec.require_path = "lib"

  spec.test_files = nil

  
    spec.add_dependency(*["map", " >= 6.5.1"])
  
    spec.add_dependency(*["fattr", " >= 2.2.1"])
  
    spec.add_dependency(*["tilt", " >= 1.3.1"])
  
    spec.add_dependency(*["pygments.rb", " >= 0.5.0"])
  
    spec.add_dependency(*["coerce", " >= 0.0.4"])
  
    spec.add_dependency(*["stringex", " >= 2.1.0"])
  
    spec.add_dependency(*["systemu", " >= 2.5.2"])
  
    spec.add_dependency(*["nokogiri", " >= 1.6.1"])
  
    spec.add_dependency(*["main", " >= 5.2.0"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/ro"
end
