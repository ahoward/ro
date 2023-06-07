[./ro, ./ro/posts, ./ro/posts/first-post, ./ro/posts/first-post/body, ./ro/posts/first-post/widget, ./ro/posts/first-post/body, ./ro/posts/first-post/widget]

class Path < ::String
  def initialize(*args, &block)
    @leaf = options[:leaf]
  end

  def prefix
    @leaf ? File.dirname(self) : self
  end
end

def loading(name, options = {}, &block)
  leaf = options[:leaf]
  last = @loading.last

  prefix = last.prefix if last

  path = [prefix, name].join('/')

  if @loading.include?(path)
    # BOOM
  end

  @loading.add(path)

  promise = Promise.new(self, name, &block)
  @loading.push promise
end

./ro/ # root.relative_path(:from => Dir.pwd.to_s)
  posts/ # collection_promise(name) 
    first_post/ # node_promise(name) 
      attributes/ # field_promise(name)

    node.load!()

    def load!
      if @root.lazy.loading?
        _load
      else
        @root.nodes[type][id]
      end
    end
^
|
|
./ro/


class Root
  def nodes
    @lazy.loading @root do
      Collection.new(:root => self)
    end
  end

  class Collection
    def initialize
      @type = :posts
    end

    def method_missing
      if subcollection_exists?(name)
        @lazy.load(name){ load_subcollection(name)}
      end
    end
  end

  def initialize
    @lazy = Lazy.new
  end

  def collections
  end
end
