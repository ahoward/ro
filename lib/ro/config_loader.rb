module Ro
  # ConfigLoader discovers and loads .ro.yml and .ro.rb configuration files
  # from the filesystem with caching support.
  #
  # Supports two file formats:
  # - .ro.yml: Static YAML configuration
  # - .ro.rb: Dynamic Ruby DSL configuration
  #
  # Precedence: .ro.rb > .ro.yml when both exist at the same level
  #
  # @example
  #   config = ConfigLoader.load('/path/to/directory')
  #   # => Map with config values or nil if no config found
  #
  class ConfigLoader
    class << self
      # Load configuration from a directory
      #
      # @param path [String, Pathname] Directory to search for config files
      # @return [Map, nil] Loaded configuration or nil if no config found
      # @raise [ConfigSyntaxError] If YAML syntax is invalid
      # @raise [ConfigEvaluationError] If Ruby DSL evaluation fails
      # @raise [ConfigPermissionError] If file cannot be read
      #
      def load(path)
        path = Pathname.new(path) unless path.is_a?(Pathname)
        return nil unless path.directory?

        # Check cache first (keyed by path + mtime)
        cache_key = cache_key_for(path)
        return @cache[cache_key] if @cache&.key?(cache_key)

        # .ro.rb takes precedence over .ro.yml
        rb_file = path.join('.ro.rb')
        yml_file = path.join('.ro.yml')

        config = if rb_file.exist?
          load_ruby(rb_file)
        elsif yml_file.exist?
          load_yaml(yml_file)
        else
          nil
        end

        # Cache result (including nil)
        @cache ||= {}
        @cache[cache_key] = config

        config
      end

      # Discover config files walking up directory tree
      #
      # Returns configs at three levels: node, collection, root
      # Used for hierarchical resolution.
      #
      # @param node_path [String, Pathname] Starting directory (node level)
      # @param collection_path [String, Pathname] Collection directory
      # @param root_path [String, Pathname] Root directory
      # @return [Hash] { node: Map|nil, collection: Map|nil, root: Map|nil }
      #
      def discover_hierarchy(node_path, collection_path, root_path)
        {
          node: load(node_path),
          collection: load(collection_path),
          root: load(root_path)
        }
      end

      # Clear the config cache
      # Useful for testing or when config files change
      #
      def clear_cache!
        @cache = {}
      end

      private

      # Load YAML configuration file
      #
      def load_yaml(file_path)
        content = File.read(file_path)
        data = YAML.safe_load(content, permitted_classes: [Symbol], aliases: true) || {}
        Map.for(data)
      rescue Psych::SyntaxError => e
        raise ConfigSyntaxError.new(
          "Invalid YAML syntax in config file",
          file_path: file_path.to_s,
          line_number: e.line,
          original_error: e,
          suggestion: "Check YAML syntax at line #{e.line}"
        )
      rescue Errno::EACCES => e
        raise ConfigPermissionError.new(
          "Cannot read config file (permission denied)",
          file_path: file_path.to_s,
          original_error: e,
          suggestion: "Run: chmod +r #{file_path}"
        )
      rescue => e
        raise ConfigError.new(
          "Failed to load YAML config file",
          file_path: file_path.to_s,
          original_error: e
        )
      end

      # Load Ruby DSL configuration file
      #
      def load_ruby(file_path)
        # Ruby DSL support will be implemented in Phase 6 (US4)
        # For now, raise an error indicating it's not yet supported
        raise ConfigEvaluationError.new(
          "Ruby DSL (.ro.rb) support not yet implemented",
          file_path: file_path.to_s,
          suggestion: "Use .ro.yml format for now, or wait for P4 implementation"
        )
      end

      # Generate cache key for a path
      # Includes mtime for invalidation
      #
      def cache_key_for(path)
        config_file = if path.join('.ro.rb').exist?
          path.join('.ro.rb')
        elsif path.join('.ro.yml').exist?
          path.join('.ro.yml')
        else
          return "#{path}:none"
        end

        mtime = config_file.mtime.to_i
        "#{path}:#{mtime}"
      end
    end
  end
end
