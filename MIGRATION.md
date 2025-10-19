# Ro v5.0 Asset Structure Migration Guide

## Overview

Ro v5.0 introduces a simplified asset directory structure that reduces nesting depth and makes assets easier to understand and manage.

### Automatic Warning System

Ro v5.0 automatically detects when you're using old structure data and warns you on stderr:

```
⚠️  WARNING: Old Ro asset structure detected!

This Ro root contains assets in the OLD structure format:
  • identifier/attributes.yml
  • identifier/assets/

Ro v5.0 uses a simplified NEW structure:
  • identifier.yml
  • identifier/

Collections will NOT automatically discover old-structure nodes.

To migrate your data, run:
  ro migrate /path/to/your/data
```

**This warning does NOT stop your program** - it's informational to help you know you need to migrate. The warning appears once per root directory when `Ro::Root.new` is called.

### Old Structure (v4.x)
```
posts/
  sample-post/
    attributes.yml       # Metadata file INSIDE node directory
    assets/             # Assets subdirectory
      image.jpg
      document.pdf
```

### New Structure (v5.0)
```
posts/
  sample-post.yml       # Metadata file at COLLECTION level (moved out)
  sample-post/          # Node directory (same location)
    assets/             # Assets subdirectory (SAME location as before!)
      image.jpg
      document.pdf
```

## Benefits

- **Simpler**: One less level of nesting
- **Clearer**: Metadata file and assets directory are siblings, not parent/child
- **Faster**: Easier to locate assets by identifier
- **More Intuitive**: Structure is self-documenting

## Migration Tool

Ro v5.0 includes a migration tool to automate the conversion from old to new structure.

### Basic Usage

```bash
# Preview migration (dry run)
./bin/ro migrate --dry-run /path/to/your/ro/root

# Run migration with backup (recommended)
./bin/ro migrate /path/to/your/ro/root

# Run migration without backup (not recommended)
./bin/ro migrate --no-backup /path/to/your/ro/root
```

### Options

- `--dry-run`, `-d`: Preview changes without making them
- `--backup`, `--no-backup`, `-b`: Create backup before migrating (default: true)
- `--verbose`, `-v`: Show detailed progress
- `--force`, `-f`: Force migration even if new structure detected
- `--help`, `-h`: Show help message

### Migration Process

The migration tool:

1. **Validates** the structure to detect old/new/mixed formats
2. **Creates a backup** (unless `--no-backup` is specified)
3. **For each old-structure node directory**:
   - **If node has attributes file**: Moves `identifier/attributes.yml` → `identifier.yml` (at collection level)
   - **If node has NO attributes**: Creates empty `identifier.yml` with `{}` content
   - Assets remain in `identifier/assets/` (no change needed!)

**Important**: The migrator processes ALL node directories, even those without an attributes file. This ensures every node is discoverable in the new structure.

### Safety Features

- **Automatic backups**: Creates timestamped backup before migration
- **Dry run mode**: Preview changes before applying
- **Validation**: Detects mixed structures and warns
- **Rollback support**: Can restore from backup if needed

## Manual Migration

If you prefer to migrate manually:

1. **For each node WITH attributes**:
   ```bash
   cd posts

   # Move metadata file out to collection level
   mv sample-post/attributes.yml sample-post.yml

   # Assets stay in sample-post/assets/
   ```

2. **For each node WITHOUT attributes** (assets-only):
   ```bash
   cd posts

   # Create empty metadata file at collection level
   echo '{}' > orphan-assets.yml

   # Assets stay in orphan-assets/assets/
   ```

3. **Update your code** to use Ro v5.0

## Rollback

If you need to rollback after migration:

```ruby
# Using the Migrator class
migrator = Ro::Migrator.new('/path/to/ro/root')
migrator.rollback
```

This will restore from the most recent backup.

## Migration Checklist

- [ ] Review migration plan with `--dry-run`
- [ ] Backup your data (migration creates backup automatically)
- [ ] Run migration: `./bin/ro migrate /path/to/ro/root`
- [ ] Verify migrated data loads correctly
- [ ] Test your application with new structure
- [ ] Update code to Ro v5.0 if needed
- [ ] Remove old backups once confident

## Breaking Changes

### API Changes

**Node initialization**:
```ruby
# Old (v4.x) - still works for backward compatibility
node = Ro::Node.new(node_directory_path)

# New (v5.0) - preferred for new structure
node = Ro::Node.new(collection, metadata_file)
```

**Asset paths**:
```ruby
# Both old and new structure
node.asset_dir  # => identifier/assets/

# The assets/ subdirectory stays the same!
# Only the metadata file location changes
```

### What Stays the Same

- **Metadata format**: YAML/JSON/TOML structure unchanged
- **Asset access**: `node.assets`, `node.asset_paths` work the same
- **Collection access**: `root['collection']['node']` unchanged
- **Attribute access**: `node[:title]`, `node.attributes` unchanged

## Testing

Run tests to verify migration:

```bash
# Unit tests
ruby test/unit/collection_test.rb
ruby test/unit/node_test.rb
ruby test/unit/asset_test.rb
ruby test/unit/migrator_test.rb

# Integration tests
ruby test/integration/ro_integration_test.rb
```

## Troubleshooting

### "Both old and new structures detected"

This indicates a partial migration. Options:
1. Use `--force` to continue migration
2. Manually inspect and resolve conflicts
3. Restore from backup and retry

### "Node directory not found"

Ensure you're running the migration from the correct root directory.

### Assets not loading after migration

Check that:
1. Metadata files are at collection level (e.g., `posts/sample-post.yml`)
2. Node directories exist at collection level (e.g., `posts/sample-post/`)
3. Assets are in the `assets/` subdirectory (e.g., `posts/sample-post/assets/image.jpg`)

## Examples

### Example 1: Single Collection

Before:
```
ro_data/
  posts/
    welcome/
      attributes.yml
      assets/
        banner.jpg
```

After:
```
ro_data/
  posts/
    welcome.yml          ← Metadata moved out
    welcome/
      assets/
        banner.jpg       ← Assets stay in same location
```

### Example 2: Multiple Collections

Before:
```
ro_data/
  posts/
    post-1/
      attributes.yml
      assets/
        image.jpg
  pages/
    about/
      attributes.yml
      assets/
        photo.png
```

After:
```
ro_data/
  posts/
    post-1.yml
    post-1/
      assets/
        image.jpg
  pages/
    about.yml
    about/
      assets/
        photo.png
```

### Example 3: Metadata-Only Node

Before:
```
ro_data/
  posts/
    text-only/
      attributes.yml
```

After:
```
ro_data/
  posts/
    text-only.yml
```

### Example 4: Assets-Only Node (No Attributes)

Before:
```
ro_data/
  posts/
    orphan-assets/     ← Directory with no attributes.yml
      assets/
        image.jpg
```

After:
```
ro_data/
  posts/
    orphan-assets.yml  ← Empty metadata file created: {}
    orphan-assets/
      assets/
        image.jpg
```

## Support

For issues or questions:
- GitHub Issues: https://github.com/ahoward/ro/issues
- Documentation: See README.md and code comments

## Version Compatibility

- **Ro v4.x**: Old structure only
- **Ro v5.0**: Both structures (with backward compatibility)
- **Ro v6.0+**: New structure only (planned)

**Recommendation**: Migrate to new structure before Ro v6.0 release.
