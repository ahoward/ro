module Ro
  class Collection
    include Klass
    include Enumerable

    attr_reader :path, :root

    def initialize(path)
      @path = Path.for(path)
      @root = Root.for(@path.parent)
    end

    def name
      @path.name
    end

    def id
      name
    end

    def type
      name
    end

    def identifier
      type
    end

    def inspect
      identifier
    end

    def node_for(path)
      Node.new(path)
    end

    def subdirectories(...)
      @path.subdirectories(...)
    end

    def subdirectory_for(name)
      @path.subdirectory_for(name)
    end

    def each(&block)
      accum = []

      subdirectories do |subdirectory|
        node = node_for(subdirectory)

        block ? block.call(node) : accum.push(node)
      end

      block ? self : accum
    end

    def to_array(...)
      each(...)
    end

    alias to_a to_array

    alias all to_array

    alias nodes to_array

    def first(*args)
      if args.size.zero?
        node_for(subdirectories.first)
      else
        subdirectories.first(*args).map{|subdirectory| node_for(subdirectory)}
      end
    end

    def last(*args)
      if args.size.zero?
        node_for(subdirectories.last)
      else
        subdirectories.last(*args).map{|subdirectory| node_for(subdirectory)}
      end
    end

    def size
      subdirectories.size
    end

    def paths_for(name)
      [
        subdirectory_for(name),
        subdirectory_for(Slug.for(name, :join => '-')),
        subdirectory_for(Slug.for(name, :join => '_')),
      ]
    end

    def get(name)
      paths_for(name).each do |path|
        next unless path.exist?

        return node_for(path)
      end

      nil
    end

    def [](name)
      get(name)
    end

    def slice(...)
      subdirectories.slice(...).map{|subdirectory| node_for(subdirectory)}
    end

    def method_missing(name, *args, **kws, &block)
      get(name) || super
    end
  end
end
