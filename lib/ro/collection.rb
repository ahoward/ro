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

    # Get effective configuration for this collection
    #
    # Merges collection-level config with root config
    #
    # @return [Map] Effective configuration
    #
    def config
      @config ||= begin
        hierarchy = ConfigHierarchy.new(
          root_path: @root.to_s,
          collection_path: @path.to_s
        )
        hierarchy.resolve
      end
    end

    def node_for(path)
      Node.new(path)
    end

    # T021: Scan for metadata files in both new and old structure formats
    # Returns array of hashes: [{id: 'node-id', path: Path, type: :new|:old}]
    def metadata_files
      extensions = %w[yml yaml json toml]
      metadata_map = {}

      # First, scan for new structure: collection-level metadata files (e.g., posts/ara.yml)
      extensions.each do |ext|
        @path.glob("*.#{ext}").each do |file|
          next unless file.file?
          node_id = file.basename.to_s.sub(/\.(yml|yaml|json|toml)$/, '')
          metadata_map[node_id] ||= {id: node_id, path: file, type: :new}
        end
      end

      # Second, scan for old structure: subdirectory attributes files (e.g., posts/ara/attributes.yml)
      subdirectories.each do |subdir|
        node_id = subdir.basename.to_s

        # Check if this subdirectory has an attributes file
        extensions.each do |ext|
          attributes_file = subdir.join("attributes.#{ext}")
          if attributes_file.exist? && attributes_file.file?
            # Only use old structure if new structure doesn't exist
            # This allows gradual migration - new structure takes precedence
            metadata_map[node_id] ||= {id: node_id, path: attributes_file, type: :old}
            break
          end
        end
      end

      # Return sorted array of metadata info
      metadata_map.values.sort_by { |m| m[:id] }
    end

    def subdirectories(...)
      @path.subdirectories(...)
    end

    def subdirectory_for(name)
      @path.subdirectory_for(name)
    end

    # T020: Modified to discover nodes from metadata files (both new and old structure)
    def each(offset:nil, limit:nil, &block)
      # Return enumerator if no block given and no offset/limit
      return to_enum(:each, offset: offset, limit: limit) unless block_given?

      # Get metadata from both old and new structure
      metadata_entries = metadata_files

      if offset
        i = -1
        n = 0
        metadata_entries.each do |entry|
          i += 1
          next if i < offset

          # Create node based on structure type
          node = if entry[:type] == :new
            Node.new(self, entry[:path])
          else
            # Old structure: pass subdirectory path
            Node.new(entry[:path].parent)
          end

          block.call(node)
          n += 1
          break if limit && n >= limit
        end
      else
        metadata_entries.each do |entry|
          # Create node based on structure type
          node = if entry[:type] == :new
            Node.new(self, entry[:path])
          else
            # Old structure: pass subdirectory path
            Node.new(entry[:path].parent)
          end

          block.call(node)
        end
      end

      self
    end

    class Page < ::Array
      attr_accessor :number

      def initialize(nodes = [], number: 1)
        replace(nodes)
        @number = number
      end
    end

    def page(number, size: 10)
      offset = [(number - 1), 0].max * size
      limit = [size, 1].max

      nodes = each(offset:, limit:)
      Page.new(nodes, number:)
    end

    def paginate(size: 10, &block)
      number = 0
      accum = []

      loop do
        number += 1
        page = self.page(number, size:)
        break if page.empty?
        block ? block.call(page) : accum.push(page)
      end

      block ? self : accum
    end

    def load(&block)
      n = 8
      q = Queue.new # FIXME
      o = Queue.new # FIXME

      producer =
        Thread.new do
          Thread.current.abort_on_exception = true

          subdirectories do |subdirectory|
            q.push(subdirectory)
          end
        end

      loaders =
        n.times.map do
          Thread.new do
            Thread.current.abort_on_exception = true

            loop do
              subdirectory = q.pop

              begin
                node = node_for(subdirectory)
                o.push(node)
              rescue => e
                o.push(e) # FIXME
                nil # FIXME
              end
            end
          end
        end

        accum = []

        consumer =
          Thread.new do
            Thread.current.abort_on_exception = true
              loop do
                node = o.pop
                block ? block.call(node) : accum.push(node)
              end
          end

        producer.join
        loaders.map{|loader| loader.join}
        consumer.join

        block ? self : accum
    end

    def to_array(offset: nil, limit: nil)
      accum = []
      each(offset: offset, limit: limit) { |node| accum << node }
      accum
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

    # T022: Modified to find nodes by metadata filename
    def get(name)
      # Try to find metadata file for this node ID
      extensions = %w[yml yaml json toml]
      extensions.each do |ext|
        metadata_file = @path.join("#{name}.#{ext}")
        if metadata_file.exist? && metadata_file.file?
          return Node.new(self, metadata_file)
        end
      end

      # Also try with slugified versions
      [
        Slug.for(name, :join => '-'),
        Slug.for(name, :join => '_')
      ].each do |slug|
        extensions.each do |ext|
          metadata_file = @path.join("#{slug}.#{ext}")
          if metadata_file.exist? && metadata_file.file?
            return Node.new(self, metadata_file)
          end
        end
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
