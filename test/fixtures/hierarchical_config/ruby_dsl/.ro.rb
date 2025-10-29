# Ruby DSL configuration fixture
structure 'dual'
enable_merge true

# Custom setting based on environment
custom_setting ENV['TEST_MODE'] == 'strict' ? 'strict_value' : 'default_value'

# Conditional configuration
if ENV['ENABLE_EXPERIMENTAL']
  experimental_features true
end
