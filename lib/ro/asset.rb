module Ro
  class Asset < ::String
    include Klass

    attr_reader :path, :node, :relative_path, :name, :url

    def initialize(arg, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}

      @path = Path.for(arg, *args)

      # T029: Updated to split on node ID instead of /assets/ segment
      @node = options.fetch(:node) do
        # Try to find node by splitting path
        # In new structure: no /assets/ segment
        # In old structure: /assets/ segment exists
        if @path.to_s.include?('/assets/')
          # Old structure
          Node.for(@path.split('/assets/').first)
        else
          # New structure: find node directory by looking at parent paths
          # Asset path like: /collection/node-id/file.jpg
          # Node path should be: /collection/node-id
          found_node = nil
          node_path = @path.parent
          while node_path && !node_path.basename.to_s.match(/\.(yml|yaml|json|toml)$/)
            # Check if there's a metadata file for this directory
            collection_path = node_path.parent
            node_id = node_path.basename.to_s

            %w[yml yaml json toml].each do |ext|
              metadata_file = collection_path.join("#{node_id}.#{ext}")
              if metadata_file.exist?
                root = Root.for(collection_path.parent)
                collection = root.collection_for(collection_path)
                found_node = Node.new(collection, metadata_file)
                break
              end
            end

            break if found_node
            node_path = node_path.parent
          end

          # Fallback: old behavior
          found_node || Node.for(@path.split('/assets/').first)
        end
      end

      # T030: Updated relative_path calculation for new structure
      # In new structure, path is already relative to node.asset_dir
      # In old structure, need to account for assets/ prefix
      @relative_path = @path.relative_to(@node.asset_dir)

      @name = @relative_path

      @url = @node.url_for(@relative_path)

      super(@path)
    end

    def is_img?
      @path.file? && Ro.is_image?(@path.basename)
    end

    alias is_img is_img?

    def img
      return unless is_img?
      Ro.image_info(path.to_s)
    end

    def is_src?
      key = relative_path.parts
      subdir = key.size > 2 ? key[1] : nil
      !!(subdir == 'src')
    end

    alias is_src is_src?

    def src
      return unless is_src?
      Ro.render_src(path, node)
    end

    def stat
      @path.stat.size
    end

    def size
      stat.size
    end
  end
end
