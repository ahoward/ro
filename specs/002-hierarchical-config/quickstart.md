# Hierarchical Configuration Quickstart

**Feature**: Hierarchical configuration system for Ro gem
**Version**: 5.3.0+
**Date**: 2025-10-29

## Overview

The Ro gem now supports hierarchical configuration through `.ro.yml` and `.ro.rb` files at three levels:

- **Root level**: `./public/ro/.ro.yml` - Applies to entire repository
- **Collection level**: `./public/ro/posts/.ro.yml` - Applies to specific collection
- **Node level**: `./public/ro/posts/my-post/.ro.yml` - Applies to specific node

Configuration follows "deeper wins" precedence: **node > collection > root > defaults**

## Quick Examples

### Example 1: Set Structure Preference at Root

Create `.ro.yml` at your Ro root directory:

```yaml
# ./public/ro/.ro.yml
structure: new
enable_merge: true
```

Now all collections will prefer the new structure (`posts/my-post.yml`) over old structure (`posts/my-post/attributes.yml`).

**Access in code:**
```ruby
root = Ro::Root.new('./public/ro')
puts root.config[:structure]  # => 'new'
```

### Example 2: Override Structure at Collection Level

Some collections need different settings:

```yaml
# ./public/ro/.ro.yml (root)
structure: new

# ./public/ro/posts/.ro.yml (collection override)
structure: old
```

Now `posts` collection uses old structure while other collections use new:

```ruby
root = Ro::Root.new('./public/ro')
posts = root.get('posts')
pages = root.get('pages')

posts.config[:structure]  # => 'old' (overridden)
pages.config[:structure]  # => 'new' (inherited from root)
```

### Example 3: Dynamic Configuration with Ruby DSL

Use `.ro.rb` for dynamic configuration:

```ruby
# ./public/ro/.ro.rb
structure ENV['RO_STRUCTURE'] || 'dual'
enable_merge true

if ENV['PRODUCTION']
  # Production settings
  custom_cache_enabled true
else
  # Development settings
  custom_cache_enabled false
end
```

Ruby files (`.ro.rb`) take precedence over YAML files (`.ro.yml`) at the same level.

### Example 4: Node-Specific Configuration

Override settings for a specific node:

```yaml
# ./public/ro/posts/special-post/.ro.yml
merge_attributes: false
custom_node_setting: special_value
```

```ruby
root = Ro::Root.new('./public/ro')
node = root.get('posts/special-post')

node.config[:merge_attributes]        # => false (node override)
node.config[:structure]                # => 'old' (inherited from collection)
node.config[:custom_node_setting]      # => 'special_value' (node only)
```

## Configuration Options

### Built-in Options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `structure` | string | `'dual'` | Metadata structure preference: `'new'`, `'old'`, or `'dual'` |
| `enable_merge` | boolean | `true` | Enable attribute merging when both metadata files exist |
| `merge_attributes` | boolean | `nil` | Node-level: merge attributes from multiple files |

### Custom Options

You can add any custom configuration keys:

```yaml
# ./public/ro/.ro.yml
structure: new
my_custom_setting: value
another_setting: 42
```

Custom keys are preserved and accessible:

```ruby
root.config[:my_custom_setting]  # => 'value'
```

## Configuration Precedence

When multiple config files exist, they merge with "deeper wins":

```
Node config
  ↓ (overrides)
Collection config
  ↓ (overrides)
Root config
  ↓ (overrides)
Defaults
```

**Example:**
```yaml
# Root: ./public/ro/.ro.yml
structure: dual
enable_merge: true
custom: root_value

# Collection: ./public/ro/posts/.ro.yml
structure: new

# Node: ./public/ro/posts/my-post/.ro.yml
enable_merge: false
```

**Result for node:**
```ruby
{
  structure: 'new',         # from collection
  enable_merge: false,      # from node
  custom: 'root_value'      # from root
}
```

## Ruby DSL Syntax

`.ro.rb` files use clean Ruby DSL syntax:

```ruby
# Simple values
structure 'new'
enable_merge true

# Conditional logic
if ENV['DEBUG']
  debug_mode true
end

# Calculations
max_items 100 * 2  # => 200

# Method calls
timestamp Time.now.to_i

# Custom nested structures
metadata_options({
  cache: true,
  ttl: 3600
})
```

## Common Use Cases

### Use Case 1: Migrate Collections Independently

Gradually migrate from old to new structure:

```yaml
# Root: Use dual (support both)
structure: dual

# Collection: posts/.ro.yml (already migrated)
structure: new

# Collection: pages/.ro.yml (not migrated yet)
structure: old
```

### Use Case 2: Environment-Specific Configuration

Different settings for dev/staging/prod:

```ruby
# .ro.rb
structure ENV['APP_ENV'] == 'production' ? 'new' : 'dual'

enable_merge ENV['APP_ENV'] != 'test'

cache_enabled ENV['APP_ENV'] == 'production'
```

### Use Case 3: Feature Flags

Enable/disable features per collection:

```yaml
# posts/.ro.yml
experimental_features: true
image_optimization: true

# pages/.ro.yml
experimental_features: false
image_optimization: false
```

### Use Case 4: Collection-Specific Behavior

Different settings for different content types:

```yaml
# posts/.ro.yml
enable_merge: true      # Merge metadata from both files
auto_publish: true

# drafts/.ro.yml
enable_merge: false     # Only use primary metadata
auto_publish: false
```

## Introspection

### View Effective Configuration

```ruby
root = Ro::Root.new('./public/ro')
posts = root.get('posts')

# Get effective (merged) config
config = posts.config
puts config.inspect

# Check specific values
puts "Structure: #{config[:structure]}"
puts "Merge enabled: #{config[:enable_merge]}"
```

### Check Configuration Source

See where each setting came from:

```ruby
hierarchy = Ro::ConfigHierarchy.new(
  root_path: './public/ro',
  collection_path: './public/ro/posts'
)

sources = hierarchy.sources
# => {
#   'structure' => :collection,
#   'enable_merge' => :root,
#   'custom' => :default
# }
```

### Check if Config Exists at Level

```ruby
hierarchy.config_exists_at?(:root)        # => true/false
hierarchy.config_exists_at?(:collection)  # => true/false
hierarchy.config_exists_at?(:node)        # => true/false
```

## Error Handling

### Invalid YAML Syntax

```yaml
# Bad .ro.yml
structure: new
invalid: yaml: syntax
```

**Error:**
```
Ro::ConfigSyntaxError: Invalid YAML syntax in config file
Location: ./public/ro/.ro.yml:2
Suggestion: Check YAML syntax at line 2
```

### Invalid Configuration Value

```yaml
# Bad .ro.yml
structure: invalid_value
```

**Error:**
```
Ro::ConfigValidationError: Configuration validation failed:
  - Invalid value for 'structure': 'invalid_value'. Valid options: new, old, dual
Suggestion: Check configuration values against schema
```

### Ruby Syntax Error

```ruby
# Bad .ro.rb
structure 'new'
end  # Extra 'end'
```

**Error:**
```
Ro::ConfigSyntaxError: Ruby syntax error in config file
Location: ./public/ro/.ro.rb:2
Suggestion: Check Ruby syntax: unexpected keyword 'end'
```

## Performance

- **Config discovery**: ~2-7ms per level (root, collection, node)
- **Total overhead**: <30ms for deeply nested node with all config levels
- **Caching**: Two-tier caching (path + mtime) minimizes filesystem access
- **Zero overhead**: When no config files exist, performance is unchanged

## Best Practices

1. **Start at root**: Define sensible defaults in root `.ro.yml`
2. **Override sparingly**: Only override at collection/node when needed
3. **Use YAML for static**: Use `.ro.yml` for static configuration
4. **Use Ruby for dynamic**: Use `.ro.rb` when you need ENV vars or logic
5. **Keep it simple**: Avoid complex Ruby logic unless necessary
6. **Document custom keys**: Add comments explaining custom configuration keys

## Migration from Current Ro

If you're using Ro without config files:

1. **Nothing changes**: All defaults remain the same
2. **Opt-in**: Add `.ro.yml` files only where you need custom behavior
3. **No breaking changes**: Existing code continues to work

Current default behavior:
```ruby
{
  structure: 'dual',      # Supports both old and new
  enable_merge: true,     # Merges when both files exist
  merge_attributes: nil   # Not set
}
```

## Next Steps

- See [spec.md](./spec.md) for complete feature specification
- See [plan.md](./plan.md) for implementation details
- See [research.md](./research.md) for design decisions

## Support

For issues or questions:
- GitHub: https://github.com/ahoward/ro/issues
- Spec: ./specs/002-hierarchical-config/
