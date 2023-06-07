@loading =
  [./ro, ./ro/posts, ./ro/posts/first-post, ./ro/posts/first-post/body, ./ro/posts/first-post/widget, ./ro/posts/first-post/body, ./ro/posts/first-post/widget]

class Path < ::String
  attr_reader :leaf

  def initialize(*args, &block)
    options = Map.extract_options!(args)
    path = Ro.path_for(*args)
    @leaf = options.fetch(:leaf){ false }
    super(path)
  end

  def leaf?
    !!leaf
  end

  def prefix
    leaf? ? File.dirname(self) : self
  end
end

class Lazy
  def loading(name, options = {}, &block)
    leaf = options[:leaf]
    last = @loading.last

    prefix = last.prefix if last

    path = [prefix, name].join('/')

    if @loading.include?(path)
      cycle = indexOf(foo) # ....
      # BOOM
    end

    @loading.add(path)

    promise = Promise.new(self, name, &block)
    @loading.push promise
  end
end

module Util
  def u
    Util
  end

  extend self
end

class Root
  def initialize
    @loader = Loader.new(self)
  end

  def collection
  end

  def load_collections(path)
  end

  def load_collection(path)
  end

  def load_node(path)
  end
end

./ro/ # root.relative_path(:from => Dir.pwd.to_s)
  posts/ # collection_promise(name)
    first_post/ # node_promise(name)
      body.md.erb # field_promise(name)
      attributes/* # field_promise(*)

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
