module Ro
  class Root < Path
    def identifier
      self
    end

    def collections(&block)
      accum = []

      subdirectories do |subdirectory|
        collection = collection_for(subdirectory)
        block ? block.call(collection) : accum.push(collection)
      end

      block ? self : accum
    end

    def collection_for(subdirectory)
      Collection.new(subdirectory)
    end

    def paths_for(name)
      [
        subdirectory_for(name),
        subdirectory_for(Slug.for(name, :join => '-')),
        subdirectory_for(Slug.for(name, :join => '_')),
      ]
    end

    def get(name)
      name = name.to_s

      if name.index('/')
        collection_name, node_name = name.split('/', 2)
        collection = get(collection_name)

        if collection
          node = collection.get(node_name)
          return node
        else
          return nil
        end
      end

      paths_for(name).each do |path|
        next unless path.directory?
        return collection_for(path)
      end

      nil
    end

    def [](name)
      get(name)
    end

    def method_missing(name, *args, **kws, &block)
      get(name) || super
    end

    def nodes(&block)
      accum = []
      
      collections.each do |collection|
        collection.nodes do |node|
          block ? block.call(node) : accum.push(node)
        end
      end

      block ? self : accum
    end
  end
end
