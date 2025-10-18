# Research: Simplify Asset Directory Structure

**Date**: 2025-10-17
**Feature**: 001-simplify-asset-structure

## Overview

This document contains research findings and technical decisions for simplifying the ro gem's asset directory structure from nested format to flattened format.

## Key Technical Decisions

### Decision 1: Node Discovery Pattern

**What was chosen**: Change from directory-based node discovery to file-based node discovery

**Rationale**:
- **Old approach**: Collections iterate subdirectories, each subdirectory is a node containing `attributes.yml`
- **New approach**: Collections scan for `.yml`/`.json`/`.toml` files, derive node identifier from filename
- **Why**: The new structure places metadata at the collection level (`identifier.yml`) rather than nested (`identifier/attributes.yml`), so node discovery must change from "find directories with attributes files" to "find metadata files, derive corresponding asset directories"

**Alternatives considered**:
- **Keep directory-based discovery**: Would require maintaining both `identifier/` directory AND `identifier.yml` file, defeating the purpose of simplification
- **Dual mode (support both)**: Adds complexity and makes migration harder; spec specifies preference for old structure until migration, not simultaneous support

**Implementation impact**:
- Modify `Collection#each` in `lib/ro/collection.rb` (lines 45-67)
- Modify `Collection#node_for` in `lib/ro/collection.rb` (line 33-35)
- Change from `subdirectories.each` to scanning for metadata files with supported extensions

### Decision 2: Node Initialization Pattern

**What was chosen**: Decouple node path from metadata file location

**Rationale**:
- **Old pattern**: `Node.new(path)` where `path` IS the node directory containing `attributes.yml`
- **New pattern**: `Node.new(path, metadata_file)` where `path` is the collection, `metadata_file` points to `identifier.yml`
- **Why**: In the old structure, the node's path was the directory containing everything. In the new structure, the metadata file is at the collection level, and the asset directory is a sibling. The node needs to know both locations.

**Alternatives considered**:
- **Metadata file only**: Pass only the metadata file path, derive everything from it. Rejected because it would require more path manipulation and lose context of the collection.
- **Keep single path parameter**: Would require complex logic to detect whether path points to old or new structure. Rejected for clarity.

**Implementation impact**:
- Modify `Node#initialize` in `lib/ro/node.rb` (lines ~20-30)
- Modify `Node#_load_base_attributes` in `lib/ro/node.rb` (lines 57-63) to load from external metadata file
- Update all Node instantiation call sites in Collection and Root classes

### Decision 3: Asset Directory Resolution

**What was chosen**: Remove `assets/` subdirectory nesting

**Rationale**:
- **Old approach**: `node.path.join('assets')` returns `identifier/assets/`
- **New approach**: `node.asset_dir` returns `identifier/` (same as node directory)
- **Why**: The new structure eliminates the `assets/` subdirectory, placing all files directly in the `identifier/` directory alongside the metadata file

**Alternatives considered**:
- **Keep `assets/` subdirectory**: Would not achieve the simplification goal from the spec
- **Flat structure (no directory at all)**: Would make it impossible to have multiple files per asset. Rejected because spec explicitly includes `identifier/` directory for "additional data"

**Implementation impact**:
- Modify `Node#asset_dir` in `lib/ro/node.rb` (line 209-211)
- Modify `Node#_ignored_files` in `lib/ro/node.rb` (lines 153-165) to update ignore patterns
- Modify `Asset` path splitting in `lib/ro/asset.rb` (line 12) - currently splits on `/assets/`

### Decision 4: Backward Compatibility Strategy

**What was chosen**: Prefer old structure until explicit migration, then breaking change in v5.0

**Rationale**:
- **User decision**: Spec FR-011 states "prefer old structure when both exist until migration"
- **User decision**: Spec FR-012 states "breaking change with major version bump"
- **Why**: Safest approach for existing users - they can test the new structure without risking data loss, then migrate when ready

**Alternatives considered**:
- **Simultaneous support**: Would require complex detection logic and feature flags. Rejected per user decision.
- **Automatic migration on load**: Too risky - could modify user data unexpectedly. Rejected for safety.

**Implementation impact**:
- Migration tool must be run explicitly by users
- Version bump from 4.4.0 → 5.0.0
- Update README and CHANGELOG to document breaking change
- Potentially add deprecation warnings in 4.x versions (out of scope for this feature)

### Decision 5: Migration Tool Design

**What was chosen**: Standalone migration script with dry-run mode

**Rationale**:
- **Pattern**: `ro migrate [collection_path] [--dry-run] [--backup]`
- **Why**:
  - Explicit operation reduces risk of accidental data modification
  - Dry-run mode allows users to preview changes
  - Backup option provides safety net
  - Can be run incrementally on specific collections

**Alternatives considered**:
- **In-place detection and migration**: Auto-migrate on first load. Rejected as too dangerous.
- **Rake task only**: Would work but less discoverable. CLI command is more user-friendly.
- **Bidirectional migration**: Support going back to old structure. Rejected as unnecessary - this is a one-way breaking change.

**Implementation impact**:
- Create `lib/ro/script/migrator.rb`
- Add CLI command in `bin/ro` or Rakefile
- Must handle:
  - Moving `identifier/attributes.yml` → `identifier.yml`
  - Moving `identifier/assets/**/*` → `identifier/`
  - Moving `identifier/body.md` and other root files → `identifier/`
  - Preserving file permissions and timestamps
  - Handling errors gracefully with rollback capability

### Decision 6: Testing Strategy

**What was chosen**: TDD approach with comprehensive test coverage before implementation

**Rationale**:
- **Current state**: No tests exist in the repository
- **Risk**: Core refactoring without tests is extremely dangerous
- **Approach**:
  1. Create tests for OLD structure first (document current behavior)
  2. Ensure all tests pass (baseline)
  3. Implement new structure
  4. Create tests for NEW structure
  5. Ensure both pass during transition
  6. Remove old structure support after migration

**Alternatives considered**:
- **Write tests after implementation**: Rejected - too risky for core refactoring
- **Minimal test coverage**: Rejected - this is a breaking change affecting all users

**Implementation impact**:
- Create `test/` directory with unit, functional, integration subdirectories
- Create test fixtures in both old and new structure formats
- Write tests for Node, Collection, Asset, Root, and Migrator classes
- Integration tests for end-to-end asset loading/writing/migration

## Technical Constraints

### File System Compatibility

**Research**: Need to support cross-platform file paths (Linux, macOS, Windows)

**Findings**:
- Ruby's `Pathname` class (already used in ro codebase) handles cross-platform paths
- YAML/JSON filename extensions are case-sensitive on Linux, case-insensitive on Windows
- Must test migration tool on all platforms

**Decision**: Continue using `Pathname`, add explicit case-handling for file extension detection

### Metadata Format Support

**Research**: Which metadata formats must be supported?

**Findings from codebase**:
- `Node#_load_base_attributes` (lib/ro/node.rb:57) uses glob: `"attributes.{yml,yaml,json}"`
- Only YAML and JSON are currently supported
- Spec mentions TOML support (FR-005)

**Decision**:
- Phase 1: Support existing formats (YAML, JSON)
- Phase 2 (optional): Add TOML support if requested
- Extension detection must be explicit: `.yml`, `.yaml`, `.json`, (`.toml`)

### Performance Considerations

**Research**: How to maintain <100ms asset lookup performance (SC-001)?

**Findings**:
- Current implementation uses `Pathname#glob` for file discovery
- Ruby's `Dir.glob` is generally fast for up to 10,000 files
- No caching is currently implemented
- Performance bottleneck is likely I/O, not directory structure

**Decision**:
- New structure should be FASTER (less nesting = fewer stat calls)
- No caching needed initially
- If performance issues arise, add memoization to Collection#nodes

## Migration Edge Cases

### Case 1: Identifier with Special Characters

**Scenario**: Asset identifier contains spaces, unicode, or special chars
**Example**: `my post!.yml` and `my post!/`

**Research**: How do filesystems handle these?
- **Linux/macOS**: Allow most characters except `/` and null
- **Windows**: Disallows `< > : " | ? * \`
- **Assumption from spec**: "Asset identifiers are valid filenames"

**Decision**: Trust the spec assumption - if it exists in old format, it should migrate cleanly

### Case 2: Metadata-Only Assets

**Scenario**: Asset has `identifier.yml` but no `identifier/` directory
**Spec reference**: FR-007 "handle metadata only"

**Decision**: Perfectly valid in new structure, no special handling needed

### Case 3: Files-Only Assets

**Scenario**: Asset has `identifier/` directory but no metadata file
**Spec reference**: FR-008 "handle files only"

**Research**: In old structure, would be `identifier/` with no `attributes.yml`

**Decision**:
- In new structure, create empty `identifier.yml` with minimal metadata
- Or: Skip during migration, log as warning
- **Requires clarification**: Ask user preference during implementation

### Case 4: Both Structures Exist

**Scenario**: Migration interrupted, both `identifier/attributes.yml` AND `identifier.yml` exist
**Spec reference**: FR-011 "prefer old structure until migrated"

**Decision**:
- Detection logic: If `identifier/attributes.yml` exists, treat as old structure (ignore `identifier.yml`)
- Migration tool should check for this and warn user
- Post-migration cleanup: Remove old structure only after verification

### Case 5: Nested Asset Directories

**Scenario**: Assets in subdirectories like `identifier/assets/images/photo.jpg`
**Edge case from spec**: "nested directories within asset directory"

**Decision**:
- Old: `identifier/assets/images/photo.jpg`
- New: `identifier/images/photo.jpg`
- Migration preserves directory structure, just removes `assets/` prefix

### Case 6: Non-Asset Files in Node Directory

**Scenario**: Files like `body.md`, `samples/`, etc. in node directory
**Example**: `public/ro/pages/disco/` has `body.md`, `samples/`, and `assets/`

**Decision**:
- Old: `identifier/body.md`, `identifier/assets/`, `identifier/samples/`
- New: All go in `identifier/`: `identifier/body.md`, `identifier/samples/`
- These are NOT in `assets/` currently, so they stay at same relative position
- `Node#_ignored_files` explicitly ignores `assets/**/**`, so these files are already treated as node content

## Dependencies and Integration Points

### Dependency 1: Pathname Library

**Usage**: Core path manipulation throughout codebase
**Impact**: None - Pathname will continue to work with new structure
**Action**: No changes needed

### Dependency 2: Front Matter Parser

**Usage**: `front_matter_parser` gem extracts YAML frontmatter from markdown
**Impact**: None - frontmatter parsing is independent of file location
**Action**: No changes needed

### Dependency 3: Kramdown

**Usage**: Markdown rendering for body content
**Impact**: None - markdown rendering is independent of file location
**Action**: No changes needed

### Integration Point 1: Static API Builder

**Location**: `lib/ro/script/builder.rb`
**Current behavior**: Iterates nodes, generates JSON API
**Impact**: Should work transparently if Node interface unchanged
**Action**: Verify builder still works after Node refactoring, add integration test

### Integration Point 2: Dev Server

**Location**: `lib/ro/script/server.rb`
**Current behavior**: Serves content from ro directory structure
**Impact**: Should work transparently if Node interface unchanged
**Action**: Test server manually after implementation

### Integration Point 3: GitHub Pages Workflow

**Location**: `.github/workflows/gh-pages.yml`
**Current behavior**: Builds static API and deploys to GitHub Pages
**Impact**: Must work with migrated `public/ro/` structure
**Action**: Migrate `public/ro/` as part of this feature, test workflow

## Best Practices

### Ruby Gem Versioning

**Research**: Semantic versioning for breaking changes
**Best practice**: Major version bump for breaking changes (4.x → 5.0)
**Action**: Update version in `lib/ro.rb` and `ro.gemspec`

### Ruby Testing Patterns

**Research**: Conventions for Ruby testing without RSpec/Minitest
**Findings**: The Rakefile already defines a custom test runner
**Best practice**: Follow existing convention (test/**/*_test.rb)
**Action**: Create tests matching existing Rake task pattern

### File System Operations

**Research**: Safe file operations in Ruby
**Best practices**:
- Use `FileUtils.mv` for moves (atomic on same filesystem)
- Use `FileUtils.cp_r` for backups
- Wrap in transactions with rollback capability
- Verify checksums before/after migration

**Action**: Implement migration with:
- Pre-migration validation
- Atomic operations where possible
- Error handling with rollback
- Post-migration verification

### Changelog and Documentation

**Research**: Documenting breaking changes
**Best practice**:
- CHANGELOG.md with clear breaking changes section
- README.md with migration guide
- Version upgrade guide

**Action**: Update documentation as part of this feature

## Open Questions

None - all clarifications were resolved during specification phase.

## References

- [Semantic Versioning](https://semver.org/) - Version numbering for breaking changes
- [Ruby Pathname Documentation](https://ruby-doc.org/stdlib-3.0.0/libdoc/pathname/rdoc/Pathname.html) - Path manipulation
- [FileUtils Documentation](https://ruby-doc.org/stdlib-3.0.0/libdoc/fileutils/rdoc/FileUtils.html) - File operations
- ro gem codebase exploration findings (see plan.md Phase 0 notes)
