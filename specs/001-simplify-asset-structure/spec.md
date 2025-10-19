# Feature Specification: Simplify Asset Directory Structure

**Feature Branch**: `001-simplify-asset-structure`
**Created**: 2025-10-17
**Status**: In Progress
**Input**: User description: "attm, ro stores assets in a directory structure like ./ro/posts/teh-slug/attributes.yml, ./ro/posts/teh-slug/assets/**.**.  we want to, instead, use a more simple structure like ./ro/posts/teh-slug.yml and ./ro/posts/teh-slug/assets/**.**.  that is to say '$identifier.yml' (or json, etc) for the main data and '$identifier/assets/**.**' for asset files"

**Clarification**: Assets remain in the `assets/` subdirectory to prevent non-asset files (like markdown, ERB templates) from being treated as assets. Only the metadata file moves from `$identifier/attributes.yml` to `$identifier.yml`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read Asset Data (Priority: P1)

Users need to access asset metadata and associated files using a simpler, more intuitive directory structure where the metadata file sits alongside the asset directory instead of being nested inside it.

**Why this priority**: This is the core structural change that affects all asset operations. Without this, no other functionality can work with the new structure.

**Independent Test**: Can be fully tested by creating an asset with the new structure (identifier.yml + identifier/ directory) and verifying that metadata can be read correctly. Delivers immediate value by making asset organization clearer.

**Acceptance Scenarios**:

1. **Given** an asset with identifier "my-post", **When** the system reads the asset, **Then** it loads metadata from `my-post.yml` and assets from `my-post/assets/` directory
2. **Given** multiple assets exist, **When** the system lists assets, **Then** it correctly identifies each asset by matching `identifier.yml` files with corresponding `identifier/assets/` directories

---

### User Story 2 - Write Asset Data (Priority: P2)

Users need to create and update assets in the new simplified structure, with metadata stored in a single file at the root level rather than nested inside a subdirectory.

**Why this priority**: Creating and modifying assets is essential for practical use, but depends on the ability to read assets correctly (P1).

**Independent Test**: Can be tested by creating a new asset, updating its metadata, and verifying the structure matches the expected pattern (`identifier.yml` + `identifier/` for files).

**Acceptance Scenarios**:

1. **Given** a new asset identifier "new-post", **When** the system creates the asset, **Then** it creates `new-post.yml` for metadata and `new-post/assets/` directory for associated files
2. **Given** an existing asset, **When** metadata is updated, **Then** changes are written to the `identifier.yml` file
3. **Given** new files are added to an asset, **When** the system saves them, **Then** files are stored in the `identifier/assets/` directory

---

### User Story 3 - Migrate Existing Assets (Priority: P3)

Users need to migrate assets from the old structure (`identifier/attributes.yml` + `identifier/assets/`) to the new structure (`identifier.yml` + `identifier/`) without data loss.

**Why this priority**: Migration is necessary for existing installations but can happen after the new structure is fully functional. New users won't need this.

**Independent Test**: Can be tested by creating assets in the old format, running migration, and verifying all data is preserved in the new format.

**Acceptance Scenarios**:

1. **Given** assets in old format (`slug/attributes.yml` + `slug/assets/`), **When** migration runs, **Then** metadata is moved to `slug.yml` and asset files remain in `slug/assets/`
2. **Given** an asset with both metadata and files, **When** migration completes, **Then** all data is accessible in the new structure with only the metadata file location changed
3. **Given** migration fails partway through, **When** the error occurs, **Then** the system can resume or rollback without data corruption

---

### Edge Cases

- What happens when both old and new structures exist for the same identifier (e.g., `post.yml` and `post/attributes.yml` both present)?
- How does the system handle assets with only metadata (no associated files directory)?
- How does the system handle assets with only files (no metadata file)?
- What happens when identifier contains special characters that might be invalid in filenames?
- How does the system handle nested directories within the asset directory (e.g., `identifier/subdir/file.txt`)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST read asset metadata from files named `{identifier}.yml` (or .json, .toml, etc.) located at the collection level
- **FR-002**: System MUST read asset files from directories named `{identifier}/assets/` located at the same collection level
- **FR-003**: System MUST write new asset metadata to `{identifier}.yml` format at the collection level
- **FR-004**: System MUST write asset files to `{identifier}/assets/` directory structure
- **FR-005**: System MUST support multiple metadata formats (YAML, JSON, TOML, etc.) based on file extension
- **FR-006**: System MUST correctly identify assets by detecting metadata files with supported extensions
- **FR-007**: System MUST handle assets that have metadata only (no directory)
- **FR-008**: System MUST handle assets that have files only (no metadata file)
- **FR-009**: System MUST provide migration capability to convert from old structure (`identifier/attributes.yml` + `identifier/assets/`) to new structure (`identifier.yml` + `identifier/assets/`)
- **FR-010**: System MUST preserve all data during migration without loss
- **FR-011**: System MUST prefer old structure (`identifier/attributes.yml`) when both old and new structures exist for the same identifier, until explicit migration is performed
- **FR-012**: This is a one-time breaking change requiring a major version bump; migration must be completed before upgrading to the new version

### Key Entities

- **Asset**: Represents a content item with an identifier, metadata (stored in `{identifier}.yml`), and optional associated files (stored in `{identifier}/` directory)
- **Collection**: A directory containing multiple assets, where each asset consists of a metadata file and optional asset directory at the same level
- **Identifier**: Unique name for an asset within a collection, used as the base name for both the metadata file and asset directory

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Assets can be located by identifier in under 100ms for collections containing up to 10,000 assets
- **SC-002**: Migration completes without data loss for 100% of assets tested
- **SC-003**: New asset structure reduces directory nesting depth by one level (from 3 to 2 levels)
- **SC-004**: Developers can understand the asset structure without documentation within 30 seconds of viewing the directory tree
- **SC-005**: Asset operations (read/write) work correctly for metadata-only assets, file-only assets, and combined assets in 100% of test cases

## Assumptions

- Asset identifiers are valid filenames in the target filesystem (no special characters that would cause filesystem errors)
- Collections are organized as directories containing multiple assets
- The system already has mechanisms for reading/writing YAML, JSON, or other structured data formats
- The old structure pattern is `{identifier}/attributes.yml` for metadata and `{identifier}/assets/` for files
- Migration is a one-time operation that can be run as a maintenance task before upgrading to the new major version
- System has file I/O capabilities to move/copy files and directories
- Users will complete migration of all assets before upgrading to the new major version
- This breaking change warrants a major version bump (e.g., 1.x.x → 2.0.0)

## Scope

### In Scope

- Reading assets in the new structure format
- Writing assets in the new structure format
- Supporting multiple metadata formats (YAML, JSON, TOML, etc.)
- Migrating existing assets from old to new structure
- Handling edge cases (metadata-only, files-only, missing identifiers)

### Out of Scope

- Changes to metadata content schema (only structure changes, not content changes)
- Performance optimization beyond basic file I/O
- Validation of metadata content (validation rules remain unchanged)
- User interface changes (this is a structural change only)
- Access control or permissions (security model remains unchanged)
