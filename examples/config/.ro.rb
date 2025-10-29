# Example Ro Configuration File (.ro.rb)
#
# Ruby DSL for dynamic configuration. Use this instead of .ro.yml when
# you need conditional logic, environment variables, or calculations.
#
# .ro.rb takes precedence over .ro.yml at the same level

# Simple configuration
structure 'new'
enable_merge true

# Environment-based configuration
if ENV['PRODUCTION']
  # Production settings
  cache_enabled true
  max_items 1000
else
  # Development settings
  cache_enabled false
  max_items 100
end

# Conditional features
if ENV['ENABLE_EXPERIMENTAL']
  experimental_features true
end

# Calculations
timestamp Time.now.to_i
version "1.0.#{ENV['BUILD_NUMBER'] || 0}"

# Custom nested structures
metadata_options({
  cache: true,
  ttl: 3600
})

# Method calls and Ruby expressions
debug ENV['DEBUG'] == 'true'
