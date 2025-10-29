# Feature Specification: Hierarchical Configuration System

**Feature Branch**: `002-hierarchical-config`
**Created**: 2025-10-29
**Status**: Draft
**Input**: User description: "we want to introdcuce a new 'ro config' concept.  thus at, for eg, a file such as ./public/ro/.ro.{yml,rb}, might be used to configure that repo.  deeper files, at the collection and node level, could add custom config to that node.  we will support a simple case (yml - state/config only) and complex case (rb - state/config + behavior).  our goal is to produce a feature that, for example, support declaring if a ro direction was new-style (posts/ara.yml) or old-style (prfer version, clearly), and other such things.  these files will alter how ro works.  we can leverate this to enabled/disable things, etc.  we will aim for a DSL for this and *a PR only* as the final goal."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Root-Level Static Configuration (Priority: P1)

As a content manager, I need to set global configuration for my entire Ro repository so that I can control fundamental behavior like metadata structure preference and feature toggles without modifying code.

**Why this priority**: This is the foundation of the config system. Without root-level configuration, the entire feature provides no value. This enables users to migrate from old to new structure and control basic behavior.

**Independent Test**: Can be fully tested by creating a `.ro.yml` file at the root level with structure preferences, loading a Ro::Root, and verifying that collections respect the configured behavior. Delivers immediate value by allowing users to declare structure preferences.

**Acceptance Scenarios**:

1. **Given** a Ro root directory with no config file, **When** I create `.ro.yml` with `structure: new`, **Then** collections prefer new-style metadata files (posts/ara.yml)
2. **Given** a Ro root with `.ro.yml` containing `structure: old`, **When** I load the root, **Then** collections prefer old-style metadata files (posts/ara/attributes.yml)
3. **Given** a `.ro.yml` with feature toggles (e.g., `enable_merge: false`), **When** collections discover nodes, **Then** the merge behavior is disabled according to config
4. **Given** a malformed `.ro.yml` file, **When** I attempt to load the root, **Then** I receive a clear error message indicating the config syntax issue
5. **Given** no `.ro.yml` file exists, **When** I load the root, **Then** default behavior is used (dual structure support with new preferred)

---

### User Story 2 - Collection-Level Configuration Override (Priority: P2)

As a content manager with multiple collections, I need different collections to use different metadata structures so that I can migrate collections independently without forcing all content to change at once.

**Why this priority**: This builds on P1 by adding per-collection granularity. It enables gradual migration strategies where some collections use new structure while others remain on old structure.

**Independent Test**: Can be tested by setting root config to `structure: new`, adding a collection-level `.ro.yml` with `structure: old` in the posts directory, and verifying that posts collection uses old structure while other collections use new structure. Delivers value for mixed-structure repositories.

**Acceptance Scenarios**:

1. **Given** root config specifies `structure: new` and posts/.ro.yml specifies `structure: old`, **When** I load the posts collection, **Then** it uses old-style metadata (posts/ara/attributes.yml)
2. **Given** root config and a collection-level config, **When** both define the same setting, **Then** collection-level config takes precedence (deeper wins)
3. **Given** a collection with `.ro.yml` and the root has no config, **When** I load that collection, **Then** collection config applies and other collections use defaults
4. **Given** collection config with invalid structure value, **When** I load the collection, **Then** I receive an error indicating the invalid value and valid options

---

### User Story 3 - Node-Level Configuration Override (Priority: P3)

As a content author, I need to configure individual nodes with custom behavior so that specific posts or pages can have specialized settings without affecting other nodes in the collection.

**Why this priority**: This completes the hierarchical system by allowing node-specific overrides. Lower priority because most use cases are handled by root and collection config. Provides fine-grained control for edge cases.

**Independent Test**: Can be tested by creating a node directory with its own `.ro.yml` file, setting node-specific config (e.g., `disable_asset_expansion: true`), loading the node, and verifying the setting applies only to that node. Delivers value for special-case content items.

**Acceptance Scenarios**:

1. **Given** a node directory (posts/special-post/) with `.ro.yml`, **When** I load that node, **Then** its config overrides collection and root settings for that node only
2. **Given** node config specifies `merge_attributes: false`, **When** both posts/special-post.yml and posts/special-post/attributes.yml exist, **Then** only the collection-level file is loaded (no merge)
3. **Given** node config with custom settings not defined at higher levels, **When** I access the node, **Then** the custom settings are available via node.config accessor
4. **Given** hierarchical configs at root, collection, and node levels, **When** I query effective config for a node, **Then** I can see the merged result with proper precedence (node > collection > root > defaults)

---

### User Story 4 - Ruby DSL Configuration (Priority: P4)

As a developer extending Ro, I need to define configuration with Ruby code so that I can add custom behavior, dynamic configuration logic, and programmatic control beyond static YAML settings.

**Why this priority**: Advanced feature for power users. Lower priority because YAML config handles most use cases. Enables custom behavior and dynamic configuration for complex scenarios.

**Independent Test**: Can be tested by creating a `.ro.rb` config file with Ruby DSL code defining custom behavior (e.g., conditional structure selection based on environment), loading the root, and verifying the dynamic config is applied. Delivers value for programmatic configuration needs.

**Acceptance Scenarios**:

1. **Given** a `.ro.rb` file with DSL defining `config.structure = ENV['RO_STRUCTURE']`, **When** I load the root with environment variable set, **Then** the structure preference matches the environment value
2. **Given** both `.ro.yml` and `.ro.rb` exist, **When** I load the config, **Then** `.ro.rb` takes precedence (Ruby more powerful/flexible than YAML)
3. **Given** a `.ro.rb` with custom behavior block (e.g., before_load hook), **When** nodes are loaded, **Then** the custom behavior executes at the appropriate time
4. **Given** a `.ro.rb` with syntax errors, **When** I attempt to load the config, **Then** I receive a clear error message with line number and description
5. **Given** a `.ro.rb` that defines invalid config values, **When** config validation runs, **Then** I receive an error listing the invalid settings and valid options

---

### Edge Cases

- What happens when `.ro.yml` and `.ro.rb` both exist at the same level? (Answer: `.ro.rb` takes precedence)
- How does the system handle circular dependencies in configuration? (Answer: Not applicable - configs are hierarchical, not interdependent)
- What happens when a config file has read permission denied? (Answer: Clear error message indicating permission issue and file path)
- How does config inheritance work when a collection is accessed directly vs through root? (Answer: Config still loads hierarchically, walking up directory tree)
- What happens when config specifies contradictory settings? (Answer: Validation catches contradictions and reports clear error)
- How are unknown config keys handled? (Answer: By default, ignored with optional strict mode that errors on unknown keys)
- What happens when config files exist but are empty? (Answer: Treated as defaults, no error)
- How does caching work when config files change? (Answer: Config is loaded once at initialization; changes require reload)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support `.ro.yml` configuration files at root, collection, and node levels
- **FR-002**: System MUST support `.ro.rb` configuration files at root, collection, and node levels
- **FR-003**: System MUST implement hierarchical config resolution where deeper configs override shallower ones (node > collection > root > defaults)
- **FR-004**: System MUST support `structure` config setting with values `new`, `old`, or `dual` to control metadata file discovery
- **FR-005**: System MUST support `enable_merge` boolean config setting to control attribute merging when both metadata files exist
- **FR-006**: System MUST validate config files on load and provide clear error messages for invalid syntax or values
- **FR-007**: System MUST give precedence to `.ro.rb` over `.ro.yml` when both exist at the same level
- **FR-008**: System MUST provide default configuration values when no config files exist
- **FR-009**: System MUST expose effective (merged) configuration via `root.config`, `collection.config`, and `node.config` accessors
- **FR-010**: System MUST support Ruby DSL in `.ro.rb` files with intuitive configuration syntax
- **FR-011**: System MUST cache loaded configuration to avoid repeated file reads during the same runtime session
- **FR-012**: System MUST allow accessing raw config at each level (root/collection/node) separate from effective merged config
- **FR-013**: System MUST support arbitrary custom config keys for user-defined settings beyond built-in options
- **FR-014**: System MUST support optional strict mode that errors on unknown config keys
- **FR-015**: System MUST provide config introspection showing where each setting originated (which file/level)

### Key Entities

- **Config**: Represents configuration at a specific level (root, collection, or node) with key-value settings
- **ConfigHierarchy**: Manages the chain of configs from root to node with proper precedence resolution
- **ConfigDSL**: Ruby-based domain-specific language for defining configuration in `.ro.rb` files with readable syntax
- **ConfigValidator**: Validates configuration values against schema, ensuring valid structure values and data types

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can switch between new and old metadata structure for entire repository by setting one config value
- **SC-002**: Users can override structure preference at collection level in under 1 minute (create `.ro.yml`, set value)
- **SC-003**: Config files are discovered and loaded within 10ms per level (root, collection, node)
- **SC-004**: 100% of invalid config syntax is caught with clear, actionable error messages before any content loading
- **SC-005**: Users can inspect effective config for any node showing complete precedence chain in single method call
- **SC-006**: Configuration changes take effect immediately on next Root initialization without code changes
- **SC-007**: DSL syntax in `.ro.rb` files reads naturally to Ruby developers (90%+ report intuitive in testing)

## Assumptions

- Config files use standard YAML syntax (1.2 specification) for `.ro.yml` files
- Ruby config files (`.ro.rb`) execute in safe context with access to Ro module
- Default structure preference is `dual` (supports both old and new simultaneously with new preferred)
- Config validation happens at load time, not at access time
- Changes to config files require reloading/reinitializing root - no hot-reload
- Config files follow same discovery pattern as metadata: walk up directory tree
- Unknown config keys are silently ignored unless strict mode is enabled
- Config files are small (< 1MB) and fully loaded into memory
- Ruby DSL in `.ro.rb` uses instance_eval or similar for clean syntax

## Open Questions

None - specification is complete for initial implementation. Future enhancements may add additional config settings as needed.

## Dependencies

- Requires Map gem (already dependency) for deep merging of hierarchical configs
- Requires YAML library (already dependency) for `.ro.yml` parsing
- No new external dependencies required

## Scope

### In Scope
- Static YAML configuration (`.ro.yml`)
- Dynamic Ruby configuration (`.ro.rb`)
- Three-level hierarchy (root, collection, node)
- Structure preference setting (`new`, `old`, `dual`)
- Merge behavior toggle (`enable_merge`)
- Config validation with clear errors
- Precedence resolution (deeper wins)
- DSL for Ruby configs
- Config introspection and debugging

### Out of Scope
- Hot-reloading of config files (changes require restart)
- Configuration UI or visual editor
- Config migration tools
- Remote/centralized config (all configs are local files)
- Config encryption or secrets management
- Version control of config changes
- Config diffing or audit logs
- Per-user or per-request configuration
- Configuration profiles or environments (can be implemented in `.ro.rb` by users)

## Deliverable

A pull request containing:
- Implementation of hierarchical config system
- Support for both `.ro.yml` and `.ro.rb` formats
- Config validation and error handling
- Documentation of config options and DSL
- Comprehensive test coverage for all user scenarios
- Example config files showing common patterns
