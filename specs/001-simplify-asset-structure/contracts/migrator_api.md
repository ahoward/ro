# Contract: Migrator API

**Version**: 5.0.0
**Date**: 2025-10-17

## Overview

Defines the interface for the migration tool that converts assets from the old structure (`identifier/attributes.yml` + `identifier/assets/`) to the new structure (`identifier.yml` + `identifier/`).

## Command Line Interface

### `ro migrate [PATH] [OPTIONS]`

**Purpose**: Migrate a collection or entire ro directory from old to new structure.

**Arguments**:
- `PATH` (optional): Path to collection or root directory (defaults to current directory)

**Options**:
- `--dry-run`: Preview migration without making changes
- `--backup [PATH]`: Create backup before migration (defaults to `PATH.backup.TIMESTAMP`)
- `--force`: Proceed even if backup exists or other warnings
- `--verbose`: Show detailed progress information
- `--rollback [BACKUP_PATH]`: Restore from a previous backup

**Examples**:
```bash
# Migrate current directory (dry run)
ro migrate --dry-run

# Migrate specific collection with backup
ro migrate ./public/ro/posts --backup

# Migrate entire ro directory
ro migrate ./public/ro --verbose

# Rollback a migration
ro migrate --rollback ./public/ro.backup.20250117-120000
```

**Exit Codes**:
- `0`: Success (all nodes migrated)
- `1`: Partial success (some nodes failed, see log)
- `2`: Fatal error (migration aborted, no changes made)
- `3`: Validation error (invalid structure, cannot migrate)

---

## Programmatic API

### `Ro::Migrator.new(path, options = {})`

**Purpose**: Create a migrator instance for a given path.

**Parameters**:
- `path` (String | Pathname): Path to collection or root directory
- `options` (Hash, optional):
  - `:dry_run` (Boolean): Preview mode (default: false)
  - `:backup` (Boolean | String): Create backup, optionally at specific path (default: false)
  - `:force` (Boolean): Skip safety checks (default: false)
  - `:verbose` (Boolean): Enable detailed logging (default: false)
  - `:logger` (Logger): Custom logger instance (default: STDOUT)

**Returns**: `Ro::Migrator` instance

**Example**:
```ruby
migrator = Ro::Migrator.new('./public/ro/posts', dry_run: true, verbose: true)
```

---

### `#migrate` → Ro::MigrationResult

**Purpose**: Execute the migration.

**Returns**: `Ro::MigrationResult` object with:
  - `#success?` (Boolean): Whether migration completed successfully
  - `#total_nodes` (Integer): Total nodes processed
  - `#migrated_nodes` (Integer): Successfully migrated nodes
  - `#failed_nodes` (Integer): Nodes that failed to migrate
  - `#skipped_nodes` (Integer): Nodes already in new structure (skipped)
  - `#errors` (Array<Hash>): Error details for failed nodes
  - `#backup_path` (Pathname): Path to backup (if created)

**Raises**:
- `Ro::MigrationError`: If fatal error occurs during migration
- `Ro::ValidationError`: If path is invalid or structure is ambiguous

**Example**:
```ruby
migrator = Ro::Migrator.new('./public/ro/posts', backup: true)
result = migrator.migrate

if result.success?
  puts "Migrated #{result.migrated_nodes} nodes successfully"
else
  puts "Migration failed: #{result.errors.count} errors"
  result.errors.each do |error|
    puts "#{error[:node_id]}: #{error[:message]}"
  end
end
```

---

### `#validate` → Boolean

**Purpose**: Validate that the path can be migrated without actually migrating.

**Returns**: Boolean (true if valid, false otherwise)

**Checks**:
- Path exists and is readable
- Path contains nodes in old structure
- No duplicate node IDs
- No permission issues
- Sufficient disk space (if backup enabled)

**Example**:
```ruby
migrator = Ro::Migrator.new('./public/ro/posts')
if migrator.validate
  puts "Ready to migrate"
else
  puts "Validation failed: #{migrator.validation_errors.join(', ')}"
end
```

---

### `#preview` → Array<Hash>

**Purpose**: Generate a preview of what will be migrated (dry run).

**Returns**: Array of hashes describing each migration step

**Example**:
```ruby
migrator = Ro::Migrator.new('./public/ro/posts')
preview = migrator.preview

preview.each do |step|
  puts "#{step[:action]}: #{step[:source]} → #{step[:destination]}"
end

# Output:
# MOVE: posts/my-post/attributes.yml → posts/my-post.yml
# MOVE: posts/my-post/assets/cover.jpg → posts/my-post/cover.jpg
# MOVE: posts/my-post/body.md → posts/my-post/body.md
# REMOVE: posts/my-post/ (empty directory)
```

---

### `#rollback(backup_path)` → Boolean

**Purpose**: Restore from a backup created during migration.

**Parameters**:
- `backup_path` (String | Pathname): Path to backup directory

**Returns**: Boolean (true if rollback successful)

**Raises**:
- `Ro::RollbackError`: If backup is invalid or rollback fails

**Example**:
```ruby
migrator = Ro::Migrator.new('./public/ro/posts')
result = migrator.migrate

if result.failed_nodes > 0
  puts "Migration failed, rolling back..."
  if migrator.rollback(result.backup_path)
    puts "Rollback successful"
  else
    puts "Rollback failed!"
  end
end
```

---

## Migration Algorithm

### Pre-Migration Phase

1. **Validation**:
   ```
   For each potential node in path:
     ✓ Check if directory contains attributes.yml (old structure)
     ✓ Check if metadata file already exists (new structure - skip)
     ✓ Check for duplicate IDs
     ✓ Verify write permissions
   ```

2. **Backup** (if enabled):
   ```
   Create backup directory: {path}.backup.{timestamp}
   Copy entire structure to backup using FileUtils.cp_r
   Verify backup integrity (checksums)
   ```

3. **Plan Migration**:
   ```
   For each node in old structure:
     - Identify: {identifier}/attributes.yml
     - Plan: Move attributes.yml → {identifier}.yml
     - Plan: Move {identifier}/assets/* → {identifier}/*
     - Plan: Move {identifier}/* (non-assets) → {identifier}/*
     - Plan: Remove {identifier}/assets/ (empty)
     - Plan: Remove {identifier}/ (if empty after above)
   ```

---

### Migration Phase

For each node (in dependency order):

1. **Create Metadata File**:
   ```ruby
   source = "#{identifier}/attributes.yml"
   dest = "#{identifier}.yml"

   FileUtils.mv(source, dest)
   verify_file(dest)
   ```

2. **Move Asset Files**:
   ```ruby
   source_dir = "#{identifier}/assets/"
   dest_dir = "#{identifier}/"

   if source_dir.exist?
     # Move all files from assets/ to identifier/
     source_dir.children.each do |child|
       dest_path = dest_dir / child.basename
       FileUtils.mv(child, dest_path)
       verify_file(dest_path)
     end

     # Remove empty assets/ directory
     source_dir.rmdir
   end
   ```

3. **Move Other Content Files**:
   ```ruby
   # Files like body.md, samples/, etc. already in identifier/
   # These stay in place (already at correct location)
   ```

4. **Cleanup**:
   ```ruby
   # If identifier/ directory is now empty, remove it
   # (This only happens if node had ONLY attributes.yml, no other files)
   if "#{identifier}/".children.empty?
     "#{identifier}/".rmdir
   end
   ```

5. **Verification**:
   ```ruby
   # Verify node can be loaded in new structure
   node = Ro::Node.new(collection, "#{identifier}.yml")
   assert node.attributes.any?, "Metadata loaded successfully"
   assert node.asset_paths.sort == original_asset_paths.sort, "All assets present"
   ```

---

### Post-Migration Phase

1. **Verify All Nodes**:
   ```
   For each migrated node:
     ✓ Metadata file exists at correct location
     ✓ All assets are accessible
     ✓ Node can be loaded via Collection API
   ```

2. **Cleanup Old Structure**:
   ```
   For each migrated node:
     ✓ Verify old attributes.yml is gone
     ✓ Verify old assets/ directory is gone
     ✓ Verify old node directory is gone (if was emptied)
   ```

3. **Generate Report**:
   ```ruby
   {
     total_nodes: 50,
     migrated_nodes: 48,
     failed_nodes: 2,
     skipped_nodes: 5,  # Already in new structure
     errors: [
       { node_id: 'broken-post', message: 'Invalid YAML in attributes.yml' },
       { node_id: 'locked-post', message: 'Permission denied' }
     ],
     backup_path: './public/ro/posts.backup.20250117-120000'
   }
   ```

---

## Error Handling

### Recoverable Errors

**Scenario**: Individual node fails (e.g., permission error)

**Behavior**:
- Log error with node ID and details
- Continue with next node
- Report error in final result
- Do NOT rollback (partial migration is acceptable)

**Example**:
```ruby
# Node 1: Success
# Node 2: Failed (permission error) ← Log and continue
# Node 3: Success
# ...
# Report: 48/50 migrated, 2 failed
```

---

### Fatal Errors

**Scenario**: Catastrophic failure (e.g., disk full, backup failed)

**Behavior**:
- Halt migration immediately
- Attempt rollback to backup (if exists)
- Exit with error code 2
- Preserve backup for manual recovery

**Example**:
```ruby
# Node 1: Success
# Node 2: Disk full! ← Fatal error
# → Attempt rollback
# → Restore from backup
# → Exit code 2
```

---

### Validation Errors

**Scenario**: Pre-migration validation fails

**Behavior**:
- Do NOT start migration
- Report all validation errors
- Exit with error code 3
- No rollback needed (no changes made)

**Example**:
```ruby
# Validation:
# ✗ Duplicate node ID: "my-post" (both my-post.yml and my-post.json exist)
# ✗ Insufficient disk space for backup
# → Exit code 3, no changes made
```

---

## Test Requirements

### Unit Tests

Must verify:

1. **Initialization**:
   - ✓ Creates migrator with valid path
   - ✓ Applies options (dry_run, backup, force, verbose)
   - ✓ Raises error for invalid path

2. **Validation**:
   - ✓ Detects old structure correctly
   - ✓ Detects new structure correctly
   - ✓ Detects mixed structures (error)
   - ✓ Detects duplicate node IDs
   - ✓ Checks write permissions
   - ✓ Validates sufficient disk space

3. **Migration**:
   - ✓ Moves attributes.yml correctly
   - ✓ Moves assets/ files correctly
   - ✓ Preserves other content files
   - ✓ Removes empty directories
   - ✓ Handles nested asset directories
   - ✓ Preserves file timestamps and permissions

4. **Backup**:
   - ✓ Creates backup before migration
   - ✓ Backup contains complete copy of original
   - ✓ Backup path is timestamped correctly

5. **Rollback**:
   - ✓ Restores from backup correctly
   - ✓ Removes partial migration artifacts
   - ✓ Validates backup before restoring

6. **Error Handling**:
   - ✓ Continues on recoverable errors
   - ✓ Halts on fatal errors
   - ✓ Logs errors with details
   - ✓ Generates accurate error reports

### Integration Tests

Must verify end-to-end migration:

1. **Full Collection Migration**:
   - ✓ Migrate collection with 10+ nodes
   - ✓ All nodes accessible via new Collection API
   - ✓ All assets accessible via new Node API
   - ✓ Old structure completely removed

2. **Partial Migration**:
   - ✓ Some nodes succeed, some fail
   - ✓ Successful nodes are in new structure
   - ✓ Failed nodes remain in old structure (if safe)
   - ✓ Errors reported accurately

3. **Edge Cases**:
   - ✓ Metadata-only node (no assets/)
   - ✓ Assets-only node (no attributes.yml) - handle gracefully
   - ✓ Node with nested asset subdirectories
   - ✓ Node with non-asset files (body.md, samples/, etc.)
   - ✓ Empty collection (no nodes)

4. **Rollback**:
   - ✓ Failed migration triggers rollback
   - ✓ Post-rollback structure matches pre-migration
   - ✓ All data preserved during rollback

---

## Success Criteria

Per spec SC-002: Migration must complete without data loss for 100% of assets tested.

**Verification**:
1. Count files before migration: N
2. Run migration
3. Count files after migration: M
4. Assert: M == N (no files lost)
5. Verify: All files accessible via new API

**Additional Checks**:
- File checksums match before/after (content unchanged)
- File permissions preserved
- Directory structure simplified (nesting depth reduced by 1)
- No orphaned files or directories
