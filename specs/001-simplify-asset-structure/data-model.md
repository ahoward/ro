# Data Model: Simplify Asset Directory Structure

**Date**: 2025-10-17
**Feature**: 001-simplify-asset-structure

## Overview

This document defines the data entities and their relationships for the simplified asset directory structure. The ro gem uses a file-based data model where entities are represented by directories and files on the filesystem.

## Core Entities

### Entity: Root

**Description**: Top-level entry point representing the ro directory structure. Contains one or more Collections.

**Attributes**:
- `path` (Pathname): Absolute path to the root directory
- `collections` (Array<Collection>): Child collections discovered by scanning subdirectories

**Relationships**:
- **Has many** Collections (1:N)

**File System Representation**:
```
/path/to/ro/
├── posts/          # Collection
├── pages/          # Collection
└── nerd/           # Collection
```

**Validation Rules**:
- Path must exist and be a directory
- Path must be readable

**State Transitions**: N/A (immutable once initialized)

---

### Entity: Collection

**Description**: A named category of related Assets (e.g., "posts", "pages"). Contains multiple Nodes. In the new structure, Collections are discovered as subdirectories of Root that contain metadata files.

**Attributes**:
- `name` (String): Collection identifier (derived from directory name)
- `path` (Pathname): Absolute path to the collection directory
- `root` (Root): Parent root instance
- `nodes` (Array<Node>): Child nodes discovered by scanning for metadata files

**Relationships**:
- **Belongs to** Root (N:1)
- **Has many** Nodes (1:N)

**File System Representation (New Structure)**:
```
/path/to/ro/posts/
├── my-first-post.yml        # Node metadata
├── my-first-post/           # Node asset directory
│   ├── body.md
│   └── cover.jpg
├── another-post.yml         # Node metadata
└── another-post/            # Node asset directory
    └── content.md
```

**File System Representation (Old Structure)**:
```
/path/to/ro/posts/
├── my-first-post/           # Node directory
│   ├── attributes.yml       # Metadata (inside node dir)
│   ├── body.md
│   └── assets/              # Asset subdirectory
│       └── cover.jpg
└── another-post/            # Node directory
    ├── attributes.yml
    └── assets/
        └── content.md
```

**Validation Rules**:
- Name must be a valid directory name
- Path must exist and be a directory
- Must contain at least one metadata file (new structure) or subdirectory (old structure)

**Discovery Logic Changes**:
- **Old**: Iterate subdirectories, each is a potential Node
- **New**: Scan for `*.{yml,yaml,json,toml}` files, derive Node from each metadata file

**State Transitions**: N/A (immutable once initialized)

---

### Entity: Node

**Description**: A single content item with metadata and optional associated files. Represents one logical asset (e.g., a blog post, page, or article).

**Attributes**:
- `id` (String): Node identifier (derived from metadata filename in new structure, directory name in old)
- `path` (Pathname): Path to node location (directory in old structure, collection path in new)
- `metadata_file` (Pathname): Path to metadata file (NEW: separate from path)
- `attributes` (Hash): Parsed metadata content (YAML/JSON/TOML)
- `collection` (Collection): Parent collection
- `assets` (Array<Asset>): Associated files (images, documents, etc.)
- `content_files` (Array<Pathname>): Non-asset files (e.g., body.md)

**Relationships**:
- **Belongs to** Collection (N:1)
- **Has many** Assets (1:N)

**File System Representation (New Structure)**:
```
Node ID: "my-post"

/path/to/ro/posts/my-post.yml    # Metadata file (at collection level)
/path/to/ro/posts/my-post/       # Asset directory (sibling to metadata)
├── body.md                       # Content file
├── image1.png                    # Asset
└── subdir/                       # Nested directory
    └── image2.jpg                # Nested asset
```

**File System Representation (Old Structure)**:
```
Node ID: "my-post"

/path/to/ro/posts/my-post/       # Node directory
├── attributes.yml                # Metadata (inside node dir)
├── body.md                       # Content file (same level as attributes)
└── assets/                       # Asset subdirectory
    ├── image1.png                # Asset
    └── subdir/                   # Nested directory
        └── image2.jpg            # Nested asset
```

**Validation Rules**:
- ID must be a valid filename (for metadata file)
- Metadata file must exist and contain valid YAML/JSON/TOML
- Asset directory is optional (metadata-only nodes are valid per FR-007)
- Metadata file is optional (files-only nodes may be supported per FR-008, but edge case)

**State Transitions**:
1. **Unloaded** → Load metadata → **Loaded**
2. **Loaded** → Update attributes → **Modified** → Save → **Loaded**
3. **Loaded** → Add asset → **Modified** → Save → **Loaded**

**Key Behavioral Changes**:
- **Old**: `Node.new(node_directory_path)` - path IS the node
- **New**: `Node.new(collection_path, metadata_file_path)` - separate metadata from assets
- **Old**: `node.asset_dir` returns `node_path/assets/`
- **New**: `node.asset_dir` returns `collection_path/node_id/`
- **Old**: `_load_base_attributes` searches for `./attributes.{yml,yaml,json}`
- **New**: `_load_base_attributes` loads from explicit `@metadata_file` path

---

### Entity: Asset

**Description**: A file associated with a Node (image, document, video, etc.). Assets are files within the node's asset directory.

**Attributes**:
- `path` (Pathname): Absolute path to the asset file
- `relative_path` (Pathname): Path relative to asset directory
- `node` (Node): Parent node
- `url` (String): Generated URL for accessing the asset

**Relationships**:
- **Belongs to** Node (N:1)

**File System Representation (New Structure)**:
```
Asset: /path/to/ro/posts/my-post/images/cover.jpg

Node: my-post
Relative path: images/cover.jpg
URL: /posts/my-post/images/cover.jpg
```

**File System Representation (Old Structure)**:
```
Asset: /path/to/ro/posts/my-post/assets/images/cover.jpg

Node: my-post
Relative path: images/cover.jpg  (assets/ prefix stripped)
URL: /posts/my-post/images/cover.jpg
```

**Validation Rules**:
- Path must exist and be a file (not directory)
- Must be within node's asset directory
- URL must be generated correctly regardless of structure

**Key Behavioral Changes**:
- **Old**: Asset paths include `/assets/` segment that must be stripped for URLs
- **New**: Asset paths are already relative to node, no stripping needed
- **Old**: `Asset` splits path on `/assets/` to find node (lib/ro/asset.rb:12)
- **New**: `Asset` splits path on node ID to find node and relative path

---

## Entity Relationships Diagram

```
Root (1)
  │
  └─ has many ─→ Collection (N)
                    │
                    └─ has many ─→ Node (N)
                                     │
                                     └─ has many ─→ Asset (N)
```

**Cardinality**:
- 1 Root : N Collections
- 1 Collection : N Nodes
- 1 Node : N Assets (0..N, assets are optional)

## Migration State Model

### Entity: MigrationState

**Description**: Tracks the migration status of a single node from old structure to new structure. Used by the migration tool to ensure safe, resumable migrations.

**Attributes**:
- `node_id` (String): Identifier of the node being migrated
- `collection_name` (String): Name of parent collection
- `source_structure` (Symbol): `:old` or `:new`
- `status` (Symbol): `:pending`, `:in_progress`, `:completed`, `:failed`, `:rolled_back`
- `metadata_migrated` (Boolean): Whether metadata file has been moved
- `assets_migrated` (Boolean): Whether asset files have been moved
- `backup_path` (Pathname): Location of backup (if created)
- `error` (String): Error message if status is `:failed`

**State Transitions**:
```
:pending
  ↓
:in_progress (metadata copied)
  ↓
:in_progress (assets copied)
  ↓
:completed (old structure removed)

OR

:in_progress
  ↓
:failed (error occurred)
  ↓
:rolled_back (restored from backup)
```

**Validation Rules**:
- Cannot transition to `:completed` unless both `metadata_migrated` and `assets_migrated` are true
- Backup must exist before attempting rollback
- Cannot re-migrate a node in `:completed` state (skip if already migrated)

---

## Data Constraints

### Uniqueness Constraints

1. **Node ID within Collection**: Each node ID must be unique within its collection
   - **Old structure**: Directory names are unique by filesystem constraint
   - **New structure**: Metadata filenames (without extension) must be unique
   - **Validation**: Migration tool must detect duplicate IDs before migrating

2. **Collection Name within Root**: Each collection name must be unique within root
   - Enforced by filesystem (directory names are unique)

### Referential Integrity

1. **Asset → Node**: Every asset must belong to a valid node
   - **Old structure**: Assets in `node_dir/assets/` are children of `node_dir`
   - **New structure**: Assets in `node_id/` are children of node with `node_id.yml`
   - **Validation**: Orphaned asset directories (no corresponding metadata file) should be flagged

2. **Node → Collection**: Every node must belong to a valid collection
   - Enforced by file system structure (nodes are discovered from collection directories)

### Format Constraints

1. **Metadata File Extensions**: Only `.yml`, `.yaml`, `.json`, `.toml` are recognized
2. **Metadata Content**: Must be valid YAML/JSON/TOML, parse errors should fail gracefully
3. **Path Characters**: Must be valid filesystem paths (platform-specific constraints)

---

## Data Format Examples

### Metadata File Content (Unchanged Between Structures)

**YAML Format** (`my-post.yml`):
```yaml
title: "My First Post"
author: "John Doe"
published_at: 2025-01-15
tags:
  - ruby
  - programming
featured_image: cover.jpg
```

**JSON Format** (`my-post.json`):
```json
{
  "title": "My First Post",
  "author": "John Doe",
  "published_at": "2025-01-15",
  "tags": ["ruby", "programming"],
  "featured_image": "cover.jpg"
}
```

### File Structure Comparison

**Old Structure**:
```
posts/
└── my-post/
    ├── attributes.yml       # Metadata
    ├── body.md              # Content
    └── assets/              # Assets subdirectory
        ├── cover.jpg
        └── diagram.png
```

**New Structure**:
```
posts/
├── my-post.yml              # Metadata (moved up one level)
└── my-post/                 # Asset directory (no more assets/ nesting)
    ├── body.md              # Content
    ├── cover.jpg
    └── diagram.png
```

**Key Differences**:
1. Metadata file moved from `posts/my-post/attributes.yml` → `posts/my-post.yml`
2. Assets moved from `posts/my-post/assets/` → `posts/my-post/`
3. Content files (`body.md`) moved from `posts/my-post/body.md` → `posts/my-post/body.md` (same relative location, but different absolute due to restructure)

---

## Performance Considerations

### Lookup Performance

**Old Structure**:
- Collection discovery: O(N) where N = subdirectories in root
- Node discovery: O(M) where M = subdirectories in collection
- Metadata loading: 1 file read per node (`attributes.yml`)

**New Structure**:
- Collection discovery: O(N) where N = subdirectories in root (unchanged)
- Node discovery: O(M) where M = metadata files in collection (file glob instead of directory iteration)
- Metadata loading: 1 file read per node (unchanged)

**Analysis**: New structure should have similar or slightly better performance because:
1. File glob for `*.yml` is typically faster than directory stat for subdirectories
2. Fewer levels of nesting = fewer filesystem operations
3. No need to look inside directories to find `attributes.yml`

**Success Criteria**: Must maintain <100ms asset lookup for 10,000 assets (SC-001)

### Memory Footprint

- **Old structure**: Minimal - only loaded node metadata is kept in memory
- **New structure**: Same - no change to memory model
- **Migration tool**: May need to load multiple nodes simultaneously, estimate ~1MB per 100 nodes

---

## Index Requirements

No database indexes are required (file-based system). However, for optimal performance:

1. **Collection-level caching**: Consider memoizing the list of metadata files in a collection
2. **Node-level caching**: Consider memoizing parsed attributes to avoid re-parsing on each access
3. **Asset-level caching**: File stats could be cached if performance becomes an issue

**Note**: Current implementation does NOT use caching. Add only if performance benchmarks indicate need.
