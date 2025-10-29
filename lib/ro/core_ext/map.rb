module Ro
  module CoreExt
    module Map
      # Deep merge for hierarchical configuration
      #
      # Unlike Map#apply which has "defaults" semantics (existing values win),
      # deep_merge implements "override" semantics where the argument wins.
      # This is essential for hierarchical config where deeper configs override
      # shallower ones (node > collection > root > defaults).
      #
      # @param other [Hash, Map] The config to merge in (this wins on conflicts)
      # @return [Map] A new Map with merged values
      #
      # @example
      #   root = Map.for(structure: 'new', merge: true, custom: 'root')
      #   collection = Map.for(structure: 'old', other: 'value')
      #   root.deep_merge(collection)
      #   # => {structure: 'old', merge: true, custom: 'root', other: 'value'}
      #
      def deep_merge(other)
        result = self.dup
        other = ::Map.for(other) unless other.is_a?(::Map)

        other.each do |key, value|
          existing = result[key]

          if value.is_a?(Hash) && existing.is_a?(Hash)
            # Recursively merge nested hashes
            result[key] = ::Map.for(existing).deep_merge(::Map.for(value))
          else
            # Override: other wins (including nil values)
            result[key] = value
          end
        end

        result
      end
    end
  end
end

# Extend Map class
::Map.send(:include, Ro::CoreExt::Map)
