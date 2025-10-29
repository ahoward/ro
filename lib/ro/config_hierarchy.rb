module Ro
  # ConfigHierarchy manages hierarchical configuration resolution
  #
  # Implements "deeper wins" precedence:
  #   node > collection > root > defaults
  #
  # Each level's config is:
  # 1. Loaded from filesystem (.ro.yml or .ro.rb)
  # 2. Validated against schema
  # 3. Merged with parent configs using deep_merge
  #
  # @example
  #   hierarchy = ConfigHierarchy.new(
  #     root_path: '/app/ro',
  #     collection_path: '/app/ro/posts',
  #     node_path: '/app/ro/posts/my-post'
  #   )
  #
  #   effective_config = hierarchy.resolve
  #   # => Map with all configs merged (node > collection > root > defaults)
  #
  class ConfigHierarchy
    attr_reader :root_path, :collection_path, :node_path
    attr_reader :root_config, :collection_config, :node_config

    # Initialize hierarchy with paths
    #
    # @param root_path [String, Pathname] Root directory path
    # @param collection_path [String, Pathname, nil] Collection directory path
    # @param node_path [String, Pathname, nil] Node directory path
    #
    def initialize(root_path:, collection_path: nil, node_path: nil)
      @root_path = Pathname.new(root_path)
      @collection_path = collection_path ? Pathname.new(collection_path) : nil
      @node_path = node_path ? Pathname.new(node_path) : nil

      load_all_configs
    end

    # Resolve effective configuration
    #
    # Merges all levels with proper precedence: node > collection > root > defaults
    #
    # @return [Map] Effective configuration
    #
    def resolve
      config = ConfigValidator.defaults

      # Apply root config
      config = config.deep_merge(@root_config) if @root_config

      # Apply collection config
      config = config.deep_merge(@collection_config) if @collection_config

      # Apply node config
      config = config.deep_merge(@node_config) if @node_config

      config
    end

    # Get config at a specific level
    #
    # @param level [Symbol] :root, :collection, or :node
    # @return [Map, nil] Config at that level (not merged)
    #
    def config_at(level)
      case level
      when :root
        @root_config
      when :collection
        @collection_config
      when :node
        @node_config
      else
        nil
      end
    end

    # Check if config exists at a specific level
    #
    # @param level [Symbol] :root, :collection, or :node
    # @return [Boolean] True if config exists at that level
    #
    def config_exists_at?(level)
      !config_at(level).nil?
    end

    # Get config source information (which file provided each setting)
    #
    # Useful for debugging and introspection
    #
    # @return [Hash] Map of setting => source level
    #
    def sources
      effective = resolve
      sources_map = {}

      effective.each_key do |key|
        source = if @node_config&.key?(key)
          :node
        elsif @collection_config&.key?(key)
          :collection
        elsif @root_config&.key?(key)
          :root
        else
          :default
        end

        sources_map[key] = source
      end

      sources_map
    end

    # Class method: Load config for a root directory
    #
    # @param root_path [String, Pathname] Root directory
    # @return [Map] Configuration for root level
    #
    def self.load_for_root(root_path)
      hierarchy = new(root_path: root_path)
      hierarchy.resolve
    end

    # Class method: Load config for a collection directory
    #
    # @param root_path [String, Pathname] Root directory
    # @param collection_path [String, Pathname] Collection directory
    # @return [Map] Configuration for collection level (merged with root)
    #
    def self.load_for_collection(root_path, collection_path)
      hierarchy = new(root_path: root_path, collection_path: collection_path)
      hierarchy.resolve
    end

    # Class method: Load config for a node directory
    #
    # @param root_path [String, Pathname] Root directory
    # @param collection_path [String, Pathname] Collection directory
    # @param node_path [String, Pathname] Node directory
    # @return [Map] Configuration for node level (merged with collection and root)
    #
    def self.load_for_node(root_path, collection_path, node_path)
      hierarchy = new(
        root_path: root_path,
        collection_path: collection_path,
        node_path: node_path
      )
      hierarchy.resolve
    end

    private

    # Load all config levels from filesystem
    #
    def load_all_configs
      @root_config = load_and_validate(@root_path)
      @collection_config = load_and_validate(@collection_path) if @collection_path
      @node_config = load_and_validate(@node_path) if @node_path
    end

    # Load config from a directory and validate it
    #
    def load_and_validate(path)
      return nil unless path

      config = ConfigLoader.load(path)
      return nil unless config

      ConfigValidator.validate!(config, strict: false)
    rescue ConfigError => e
      # Re-raise config errors as-is
      raise e
    rescue => e
      # Wrap unexpected errors
      raise ConfigError.new(
        "Unexpected error loading config",
        file_path: path.to_s,
        original_error: e
      )
    end
  end
end
