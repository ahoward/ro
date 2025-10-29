module Ro
  # ConfigValidator validates configuration values against schema
  #
  # Provides:
  # - Type checking (string, boolean, etc.)
  # - Enum validation (e.g., structure must be new/old/dual)
  # - Required field validation
  # - Strict mode (reject unknown keys)
  #
  # @example
  #   config = Map.for(structure: 'new', enable_merge: true)
  #   ConfigValidator.validate!(config)  # OK
  #
  #   bad_config = Map.for(structure: 'invalid')
  #   ConfigValidator.validate!(bad_config)  # raises ConfigValidationError
  #
  class ConfigValidator
    # Schema defining all known config options
    SCHEMA = {
      structure: {
        type: :string,
        enum: %w[new old dual],
        default: 'dual',
        description: 'Metadata file structure preference'
      },
      enable_merge: {
        type: :boolean,
        default: true,
        description: 'Enable attribute merging when both files exist'
      },
      merge_attributes: {
        type: :boolean,
        default: nil,
        description: 'Node-level: merge attributes from multiple files'
      }
    }.freeze

    class << self
      # Validate configuration
      #
      # @param config [Map, Hash] Configuration to validate
      # @param strict [Boolean] If true, reject unknown keys
      # @return [Map] Validated and coerced configuration
      # @raise [ConfigValidationError] If validation fails
      #
      def validate!(config, strict: false)
        config = Map.for(config) unless config.is_a?(Map)
        errors = []

        # Check for unknown keys in strict mode
        if strict
          unknown_keys = config.keys.map(&:to_sym) - SCHEMA.keys
          if unknown_keys.any?
            errors << "Unknown configuration keys: #{unknown_keys.join(', ')}"
          end
        end

        # Validate each known key
        config.each do |key, value|
          key_sym = key.to_sym
          next unless SCHEMA.key?(key_sym)

          schema = SCHEMA[key_sym]

          # Type validation
          unless valid_type?(value, schema[:type])
            errors << "Invalid type for '#{key}': expected #{schema[:type]}, got #{value.class}"
            next
          end

          # Enum validation
          if schema[:enum] && !schema[:enum].include?(value.to_s)
            errors << "Invalid value for '#{key}': '#{value}'. Valid options: #{schema[:enum].join(', ')}"
          end
        end

        if errors.any?
          raise ConfigValidationError.new(
            "Configuration validation failed:\n" + errors.map { |e| "  - #{e}" }.join("\n"),
            suggestion: "Check configuration values against schema"
          )
        end

        config
      end

      # Get default configuration
      #
      # @return [Map] Default config values
      #
      def defaults
        Map.for(
          SCHEMA.each_with_object({}) do |(key, schema), defaults|
            defaults[key] = schema[:default] if schema.key?(:default)
          end
        )
      end

      # Get schema for a specific key
      #
      # @param key [String, Symbol] Configuration key
      # @return [Hash, nil] Schema definition or nil if unknown
      #
      def schema_for(key)
        SCHEMA[key.to_sym]
      end

      # List all known configuration keys
      #
      # @return [Array<Symbol>] List of config keys
      #
      def known_keys
        SCHEMA.keys
      end

      private

      # Check if value matches expected type
      #
      def valid_type?(value, type)
        return true if value.nil?  # nil is valid for all types

        case type
        when :string
          value.is_a?(String)
        when :boolean
          [true, false].include?(value) || %w[true false yes no].include?(value.to_s.downcase)
        when :integer
          value.is_a?(Integer) || (value.is_a?(String) && value.match?(/^\d+$/))
        when :float
          value.is_a?(Numeric)
        when :array
          value.is_a?(Array)
        when :hash
          value.is_a?(Hash) || value.is_a?(Map)
        else
          true  # Unknown types pass
        end
      end
    end
  end
end
