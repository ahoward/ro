# Contract: Node API

**Version**: 5.0.0 (new structure)
**Date**: 2025-10-17

## Overview

Defines the programmatic interface for the `Ro::Node` class in the new simplified asset structure. This contract ensures that the Node API remains stable and predictable for library consumers.

## Constructor

### `Node.new(collection, metadata_file)`

**Purpose**: Initialize a new Node instance from a metadata file in the new structure.

**Parameters**:
- `collection` (Ro::Collection): Parent collection object
- `metadata_file` (Pathname): Path to the metadata file (e.g., `posts/my-post.yml`)

**Returns**: `Ro::Node` instance

**Raises**:
- `Errno::ENOENT`: If metadata_file does not exist
- `YAML::SyntaxError`, `JSON::ParserError`: If metadata file is malformed

**Example**:
```ruby
collection = Ro::Collection.new(root, 'posts')
metadata_file = Pathname.new('/path/to/ro/posts/my-post.yml')
node = Ro::Node.new(collection, metadata_file)
```

**Backward Compatibility Note**:
In the old structure (v4.x), Node was initialized with a directory path:
```ruby
# OLD (v4.x):
node = Ro::Node.new(collection, '/path/to/ro/posts/my-post')

# NEW (v5.0):
node = Ro::Node.new(collection, '/path/to/ro/posts/my-post.yml')
```

---

## Instance Methods

### `#id` → String

**Purpose**: Returns the unique identifier for this node (derived from metadata filename).

**Returns**: String (e.g., "my-post")

**Example**:
```ruby
node.id  # => "my-post"
```

**Derivation**:
- Old structure: Basename of node directory (e.g., `posts/my-post/` → "my-post")
- New structure: Basename of metadata file without extension (e.g., `posts/my-post.yml` → "my-post")

---

### `#path` → Pathname

**Purpose**: Returns the path to the node's asset directory.

**Returns**: Pathname

**Example**:
```ruby
node.path  # => #<Pathname:/path/to/ro/posts/my-post>
```

**Behavior Change**:
- Old structure: Path to directory containing `attributes.yml` (e.g., `/posts/my-post/`)
- New structure: Path to directory containing assets (e.g., `/posts/my-post/`), derived from metadata filename

---

### `#metadata_file` → Pathname

**Purpose**: Returns the path to the metadata file (NEW in v5.0).

**Returns**: Pathname

**Example**:
```ruby
node.metadata_file  # => #<Pathname:/path/to/ro/posts/my-post.yml>
```

**Note**: This is a new method in v5.0. In v4.x, metadata was always at `node.path / 'attributes.yml'`.

---

### `#attributes` → Hash

**Purpose**: Returns the parsed metadata as a hash.

**Returns**: Hash with symbol keys

**Example**:
```ruby
node.attributes  # => { title: "My Post", author: "John", tags: ["ruby"] }
```

**Unchanged**: This method works the same in both old and new structures.

---

### `#[]` (alias: `#get`, `#fetch`) → Object

**Purpose**: Access a specific attribute by key.

**Parameters**:
- `key` (String or Symbol): Attribute name

**Returns**: Attribute value or nil

**Example**:
```ruby
node[:title]        # => "My Post"
node.get(:author)   # => "John"
```

**Unchanged**: This method works the same in both old and new structures.

---

### `#asset_dir` → Pathname

**Purpose**: Returns the path to the directory containing assets.

**Returns**: Pathname

**Example**:
```ruby
node.asset_dir  # => #<Pathname:/path/to/ro/posts/my-post>
```

**Behavior Change**:
- Old structure: `node.path / 'assets'` (e.g., `/posts/my-post/assets/`)
- New structure: `node.path` (e.g., `/posts/my-post/`)

---

### `#asset_paths` → Array<Pathname>

**Purpose**: Returns paths to all files in the asset directory.

**Returns**: Array of Pathname objects (sorted)

**Example**:
```ruby
node.asset_paths  # => [#<Pathname:.../cover.jpg>, #<Pathname:.../diagram.png>]
```

**Behavior Change**:
- Old structure: Files from `node.path / 'assets'`
- New structure: Files from `node.path` (excluding ignored files)

---

### `#assets` → Array<Ro::Asset>

**Purpose**: Returns Asset objects for all files in the asset directory.

**Returns**: Array of `Ro::Asset` instances

**Example**:
```ruby
node.assets  # => [#<Ro::Asset path=.../cover.jpg>, #<Ro::Asset path=.../diagram.png>]
```

**Unchanged**: Returns Asset instances regardless of structure.

---

### `#update_attributes!(attrs, file: nil)` → void

**Purpose**: Updates node metadata and saves to disk.

**Parameters**:
- `attrs` (Hash): New attribute values
- `file` (Pathname, optional): Specific file to save to (defaults to metadata_file)

**Returns**: void

**Raises**:
- `Errno::EACCES`: If metadata file is not writable

**Example**:
```ruby
node.update_attributes!(title: "Updated Title", author: "Jane")
```

**Behavior Change**:
- Old structure: Saves to `node.path / 'attributes.yml'`
- New structure: Saves to `node.metadata_file` (e.g., `posts/my-post.yml`)

---

## Test Requirements

### Unit Tests

Must verify for the NEW structure:

1. **Initialization**:
   - ✓ Creates node from metadata file
   - ✓ Derives ID from filename (without extension)
   - ✓ Raises error if metadata file doesn't exist
   - ✓ Raises error if metadata file is malformed

2. **Attribute Access**:
   - ✓ Loads attributes from metadata file
   - ✓ Returns correct values for `#[]`, `#get`, `#fetch`
   - ✓ Returns Hash for `#attributes`

3. **Asset Management**:
   - ✓ `#asset_dir` returns correct path (node directory, not assets/ subdirectory)
   - ✓ `#asset_paths` returns files from node directory
   - ✓ `#assets` returns Asset instances
   - ✓ Ignores metadata file itself (don't treat as asset)

4. **Metadata Updates**:
   - ✓ `#update_attributes!` saves to correct metadata file
   - ✓ Preserves existing attributes when updating subset
   - ✓ Handles file write errors gracefully

### Integration Tests

Must verify interaction between Node, Collection, and Asset:

1. **Node Discovery**:
   - ✓ Collection finds nodes by detecting metadata files
   - ✓ Node ID matches metadata filename (without extension)
   - ✓ Node path corresponds to asset directory

2. **Asset Resolution**:
   - ✓ Assets resolve to correct URLs
   - ✓ Nested assets (subdirectories) work correctly
   - ✓ Asset paths are relative to node directory (no `assets/` prefix)

3. **Metadata Formats**:
   - ✓ Supports YAML (`.yml`, `.yaml`)
   - ✓ Supports JSON (`.json`)
   - ✓ Handles missing optional asset directory

---

## Migration Compatibility

### Transition Period

During migration from v4.x to v5.0, the Node class must:

1. **Detect old structure**: If initialized with a directory path (old API), detect old structure
2. **Prefer old structure**: Per FR-011, if both structures exist, use old structure
3. **Fail gracefully**: If neither structure exists, raise clear error

**Pseudo-code for compatibility**:
```ruby
def initialize(collection, path_or_metadata)
  if path_or_metadata.directory?
    # Old structure (v4.x compatibility)
    @path = path_or_metadata
    @metadata_file = @path / 'attributes.yml'
  elsif path_or_metadata.file?
    # New structure (v5.0)
    @metadata_file = path_or_metadata
    @path = derive_asset_directory_from_metadata_file
  else
    raise "Invalid node: #{path_or_metadata}"
  end
end
```

**NOTE**: This compatibility code is ONLY for migration period. In final v5.0 release, only the new signature should be supported.

---

## Breaking Changes from v4.x

| Method | v4.x Behavior | v5.0 Behavior | Breaking? |
|--------|---------------|---------------|-----------|
| `Node.new` | Accepts directory path | Accepts metadata file path | YES |
| `#path` | Returns node directory | Returns asset directory (same location) | NO |
| `#asset_dir` | Returns `path/assets/` | Returns `path` | YES |
| `#metadata_file` | N/A (implicit) | Returns explicit metadata file path | NEW |
| `#id` | From directory name | From metadata filename | NO (same value) |
| `#attributes` | Loaded from `path/attributes.yml` | Loaded from `metadata_file` | NO (same data) |

**Migration Impact**: Code that calls `Node.new` directly must be updated. Code that uses Node instances should mostly work unchanged, except for `#asset_dir` which now points to the node directory instead of `assets/` subdirectory.
