# Contract: Collection API

**Version**: 5.0.0 (new structure)
**Date**: 2025-10-17

## Overview

Defines the programmatic interface for the `Ro::Collection` class in the new simplified asset structure. Collections discover and manage Nodes using the new metadata file-based pattern.

## Constructor

### `Collection.new(root, name)`

**Purpose**: Initialize a collection from a root and collection name.

**Parameters**:
- `root` (Ro::Root): Parent root object
- `name` (String): Collection name (matches directory name)

**Returns**: `Ro::Collection` instance

**Example**:
```ruby
root = Ro::Root.new('/path/to/ro')
collection = Ro::Collection.new(root, 'posts')
```

**Unchanged**: Constructor signature remains the same in both v4.x and v5.0.

---

## Instance Methods

### `#name` → String

**Purpose**: Returns the collection name.

**Returns**: String (e.g., "posts")

**Example**:
```ruby
collection.name  # => "posts"
```

**Unchanged**: Same in both structures.

---

### `#path` → Pathname

**Purpose**: Returns the path to the collection directory.

**Returns**: Pathname

**Example**:
```ruby
collection.path  # => #<Pathname:/path/to/ro/posts>
```

**Unchanged**: Same in both structures.

---

### `#nodes` → Array<Ro::Node>

**Purpose**: Returns all nodes in the collection.

**Returns**: Array of `Ro::Node` instances

**Example**:
```ruby
collection.nodes  # => [#<Ro::Node id="post-1">, #<Ro::Node id="post-2">]
```

**Behavior Change**:
- Old structure: Discovers nodes by iterating subdirectories
- New structure: Discovers nodes by finding metadata files (`.yml`, `.yaml`, `.json`, `.toml`)

**Unchanged**: Return type and usage remain the same.

---

### `#each(&block)` → Enumerator

**Purpose**: Iterates over each node in the collection.

**Parameters**:
- `block` (optional): Block to execute for each node

**Returns**: Enumerator if no block given

**Example**:
```ruby
collection.each do |node|
  puts node.id
end

# Or without block:
collection.each.map(&:id)  # => ["post-1", "post-2"]
```

**Behavior Change**:
- Old structure: Iterates subdirectories, creates Node from each
- New structure: Iterates metadata files, creates Node from each

**Unchanged**: API remains the same, only discovery mechanism changes.

---

### `#node_for(identifier)` → Ro::Node | nil

**Purpose**: Returns a specific node by identifier.

**Parameters**:
- `identifier` (String): Node ID

**Returns**: `Ro::Node` instance, or `nil` if not found

**Example**:
```ruby
node = collection.node_for('my-post')  # => #<Ro::Node id="my-post">
missing = collection.node_for('nonexistent')  # => nil
```

**Behavior Change**:
- Old structure: Looks for subdirectory named `identifier`
- New structure: Looks for metadata file named `identifier.{yml,yaml,json,toml}`

**Unchanged**: API remains the same.

---

### `#[]` (alias: `#get`) → Ro::Node | nil

**Purpose**: Access a specific node by identifier (alias for `#node_for`).

**Parameters**:
- `identifier` (String): Node ID

**Returns**: `Ro::Node` instance, or `nil` if not found

**Example**:
```ruby
node = collection['my-post']  # => #<Ro::Node id="my-post">
```

**Unchanged**: Same in both structures.

---

### `#size` (alias: `#count`, `#length`) → Integer

**Purpose**: Returns the number of nodes in the collection.

**Returns**: Integer

**Example**:
```ruby
collection.size  # => 42
```

**Unchanged**: Same in both structures (just counts discovered nodes).

---

## Discovery Logic (Internal)

### OLD Structure Discovery (v4.x):

```ruby
def each(&block)
  subdirectories.each do |subdir|
    node = Ro::Node.new(self, subdir)
    block.call(node)
  end
end

def subdirectories
  path.children.select(&:directory?).sort
end
```

**Pattern**: Iterate directories → each directory is a node → node loads `attributes.yml` internally

---

### NEW Structure Discovery (v5.0):

```ruby
def each(&block)
  metadata_files.each do |metadata_file|
    node = Ro::Node.new(self, metadata_file)
    block.call(node)
  end
end

def metadata_files
  extensions = %w[yml yaml json toml]
  extensions.flat_map do |ext|
    path.glob("*.#{ext}").select(&:file?)
  end.sort
end
```

**Pattern**: Scan for metadata files → each file is a node → node derives ID from filename

---

## Test Requirements

### Unit Tests

Must verify for the NEW structure:

1. **Initialization**:
   - ✓ Creates collection from root and name
   - ✓ Sets correct path (`root.path / name`)

2. **Node Discovery**:
   - ✓ Finds nodes by detecting metadata files
   - ✓ Supports multiple metadata formats (`.yml`, `.yaml`, `.json`, `.toml`)
   - ✓ Ignores non-metadata files
   - ✓ Returns nodes in sorted order (by filename)
   - ✓ Handles empty collection (no metadata files)

3. **Node Access**:
   - ✓ `#node_for` returns correct node by ID
   - ✓ `#node_for` returns `nil` for missing nodes
   - ✓ `#[]` works as alias for `#node_for`

4. **Enumeration**:
   - ✓ `#each` iterates over all nodes
   - ✓ `#each` returns Enumerator when no block given
   - ✓ `#nodes` returns array of all nodes
   - ✓ `#size` returns correct count

### Integration Tests

Must verify interaction with Root and Node:

1. **Collection Discovery**:
   - ✓ Root discovers collections as subdirectories
   - ✓ Collections discover nodes as metadata files within those subdirectories

2. **Node Creation**:
   - ✓ Collection passes correct metadata file path to Node constructor
   - ✓ Created nodes have correct collection reference
   - ✓ Created nodes have IDs matching metadata filenames (without extension)

3. **Mixed Formats**:
   - ✓ Collection with both `.yml` and `.json` nodes works correctly
   - ✓ Nodes with same ID but different extensions are detected as conflicts

---

## Edge Cases

### Multiple Metadata Files for Same ID

**Scenario**: Both `my-post.yml` and `my-post.json` exist

**Expected Behavior**:
- **Strict mode**: Raise error (ambiguous node)
- **Lenient mode**: Use first found (alphabetically: `.json` < `.yml`)

**Recommendation**: Raise error to prevent confusion. Users should have only one metadata file per node.

**Test**:
```ruby
# Given:
# posts/my-post.yml
# posts/my-post.json

expect { collection.node_for('my-post') }.to raise_error(Ro::AmbiguousNodeError)
```

---

### Metadata File with No Corresponding Directory

**Scenario**: `my-post.yml` exists but no `my-post/` directory

**Expected Behavior**: Valid (metadata-only node per FR-007)

**Test**:
```ruby
# Given:
# posts/my-post.yml
# (no posts/my-post/ directory)

node = collection.node_for('my-post')
expect(node).to be_present
expect(node.asset_paths).to be_empty
```

---

### Directory with No Corresponding Metadata File

**Scenario**: `my-post/` directory exists but no `my-post.yml`

**Expected Behavior**: Not discovered as a node (metadata file is the authority)

**Test**:
```ruby
# Given:
# posts/my-post/
# (no posts/my-post.yml)

node = collection.node_for('my-post')
expect(node).to be_nil
```

**Rationale**: Metadata file presence is the canonical marker for a node. Orphaned directories should be ignored or flagged as warnings.

---

### Both Old and New Structure Exist

**Scenario**: Both `my-post/attributes.yml` (old) and `my-post.yml` (new) exist

**Expected Behavior** (per FR-011): Prefer old structure until migration

**Test**:
```ruby
# Given:
# posts/my-post/attributes.yml  (old structure)
# posts/my-post.yml             (new structure)

# In v5.0 (post-migration), only new structure should be detected:
node = collection.node_for('my-post')
expect(node.metadata_file.to_s).to end_with('my-post.yml')  # NEW structure
```

**NOTE**: This scenario should only occur during migration. The migration tool should prevent this by removing old structure after verifying new structure.

---

## Breaking Changes from v4.x

| Method | v4.x Behavior | v5.0 Behavior | Breaking? |
|--------|---------------|---------------|-----------|
| `#each` | Iterates subdirectories | Iterates metadata files | NO (internal change) |
| `#nodes` | Nodes from subdirectories | Nodes from metadata files | NO (same interface) |
| `#node_for` | Looks for `id/` directory | Looks for `id.{yml,json,...}` file | NO (same interface) |

**Migration Impact**: External API remains unchanged. The only breaking change is in how nodes are discovered internally, which is transparent to library users. However, users must migrate their data from old to new structure before upgrading to v5.0.

---

## Performance Considerations

### Discovery Performance

**Old structure**:
```ruby
path.children.select(&:directory?)  # O(N) where N = files + directories
```

**New structure**:
```ruby
path.glob("*.yml") + path.glob("*.json") + ...  # O(M) where M = total files
```

**Analysis**:
- Old: Must stat every entry to check if directory
- New: Must glob for each extension (typically 2-4 globs)
- **Result**: Similar performance, potentially faster for new structure (globs are optimized)

**Benchmark target**: <100ms for collections with 10,000 nodes (per SC-001)

---

## Migration Compatibility

### Transition Strategy

During migration from v4.x to v5.0, the Collection class should:

1. **Detect structure type**: Check if nodes exist as metadata files (new) or subdirectories (old)
2. **Raise error for mixed structures**: If some nodes are old and some are new, raise error directing user to run migration tool
3. **Log deprecation warnings**: In v4.x, log warning if old structure detected

**Implementation suggestion**:
```ruby
def each(&block)
  if new_structure?
    # Use metadata file discovery
    metadata_files.each { |f| yield Ro::Node.new(self, f) }
  elsif old_structure?
    # Use directory discovery (v4.x compatibility)
    subdirectories.each { |d| yield Ro::Node.new(self, d) }
  else
    raise "Mixed structures detected. Run migration tool first."
  end
end

def new_structure?
  metadata_files.any?
end

def old_structure?
  subdirectories.any? { |d| (d / 'attributes.yml').exist? }
end
```

**NOTE**: This compatibility code is ONLY for migration period. In final v5.0 release, only new structure should be supported.
