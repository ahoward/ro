module Ro
  class Root < Path
    @@warned_paths = {}

    def identifier
      self
    end

    def initialize(*)
      super
      check_for_unmigrated_structure!
    end

    def collections(&block)
      accum = Collection::List.for(self)

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

    def nodes(&block)
      accum = []
      
      collections.each do |collection|
        collection.nodes do |node|
          block ? block.call(node) : accum.push(node)
        end
      end

      block ? self : accum
    end

    def method_missing(name, *args, **kws, &block)
      get(name) || super
    end

    private

    def check_for_unmigrated_structure!
      # Use absolute path for deduplication
      begin
        path_key = File.expand_path(self.to_s)
      rescue
        path_key = self.to_s
      end

      # Skip if we've already warned for this path
      return if @@warned_paths[path_key]

      # Mark as checked (even if no warning needed)
      @@warned_paths[path_key] = true

      # Quick check: look for old structure (subdirs with attributes.yml)
      # but no new structure (metadata files at collection level)
      has_old = false
      has_new = false

      subdirectories.each do |subdir|
        # Check for new structure (metadata files)
        has_new = true if subdir.glob('*.{yml,yaml,json,toml}').any? { |f| f.file? }

        # Check for old structure (nested attributes.yml)
        subdir.subdirectories.each do |node_dir|
          if (node_dir.join('attributes.yml').exist? ||
              node_dir.join('attributes.yaml').exist? ||
              node_dir.join('attributes.json').exist?)
            has_old = true
            break
          end
        end

        break if has_old && has_new
      end

      if has_old && !has_new
        warn_unmigrated_structure!
      end
    end

    def warn_unmigrated_structure!
      $stderr.puts ""
      $stderr.puts "=" * 70
      $stderr.puts "⚠️  WARNING: Old Ro asset structure detected!"
      $stderr.puts "=" * 70
      $stderr.puts ""
      $stderr.puts "This Ro root contains assets in the OLD structure format:"
      $stderr.puts "  • identifier/attributes.yml"
      $stderr.puts "  • identifier/assets/"
      $stderr.puts ""
      $stderr.puts "Ro v5.0 uses a simplified NEW structure:"
      $stderr.puts "  • identifier.yml"
      $stderr.puts "  • identifier/"
      $stderr.puts ""
      $stderr.puts "Collections will NOT automatically discover old-structure nodes."
      $stderr.puts ""
      $stderr.puts "To migrate your data, run:"
      $stderr.puts "  #{$0.include?('bin/') ? './bin/ro-migrate' : 'ro-migrate'} #{self}"
      $stderr.puts ""
      $stderr.puts "Or see MIGRATION.md for details."
      $stderr.puts "=" * 70
      $stderr.puts ""
    end
  end
end
