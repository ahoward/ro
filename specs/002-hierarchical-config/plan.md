# Implementation Plan: Hierarchical Configuration System

**Branch**: `002-hierarchical-config` | **Date**: 2025-10-29 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-hierarchical-config/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a hierarchical configuration system for Ro that allows `.ro.yml` and `.ro.rb` files at root, collection, and node levels to control behavior such as metadata structure preference (`new`, `old`, `dual`) and feature toggles like attribute merging. Configurations follow "deeper wins" precedence (node > collection > root > defaults) with Ruby DSL support for advanced use cases. This complements the existing `Ro::Config` class (runtime settings) by adding file-based, hierarchical configuration that affects discovery and loading behavior.

## Technical Context

**Language/Version**: Ruby >= 3.0 (per gemspec requirement)
**Primary Dependencies**:
  - Map gem (~> 6.6) - for deep merging hierarchical configs
  - YAML library (stdlib) - for `.ro.yml` parsing
  - Existing: Ro::Path, Ro::Root, Ro::Collection, Ro::Node classes

**Storage**: Filesystem (.ro.yml and .ro.rb files at root/collection/node directories)
**Testing**: Minitest (current test framework per test_helper.rb)
**Target Platform**: Ruby gem (cross-platform)
**Project Type**: Single library project
**Performance Goals**:
  - Config discovery and load: <10ms per level (root, collection, node)
  - Total config resolution for deeply nested node: <30ms
  - Minimal impact on existing metadata discovery (~0.3ms/node overhead acceptable per performance.md)

**Constraints**:
  - Must not break existing behavior when no config files present
  - Config changes require Root re-initialization (no hot-reload)
  - Config files must be small (<1MB, fully loaded into memory)
  - Must maintain backward compatibility with existing Ro::Config class

**Scale/Scope**:
  - Support repositories with 100s of nodes across multiple collections
  - Three-level hierarchy (root, collection, node)
  - 2 config formats (.yml static, .rb dynamic)
  - ~15 configuration options initially (structure, enable_merge, etc.)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: Constitution file is a template placeholder - proceeding with standard Ruby gem best practices:

✓ **Library-First**: Hierarchical config will be self-contained classes (Ro::ConfigLoader, Ro::ConfigHierarchy, etc.)
✓ **CLI Interface**: Config introspection available via `ro config show` command
✓ **Test-First**: Will write tests before implementation (existing test suite uses Minitest)
✓ **Integration Testing**: Required for hierarchical resolution, precedence rules, file discovery
✓ **Simplicity**: Start with YAML support (P1-P2), add Ruby DSL later (P4)

**No violations** - straightforward addition to existing codebase following established patterns.

## Project Structure

### Documentation (this feature)

```
specs/002-hierarchical-config/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
lib/ro/
├── config_loader.rb         # NEW: Discovers and loads .ro.{yml,rb} files
├── config_hierarchy.rb      # NEW: Manages root -> collection -> node precedence
├── config_dsl.rb            # NEW: Ruby DSL for .ro.rb files (P4 priority)
├── config_validator.rb      # NEW: Validates config values and schema
├── config.rb                # EXISTING: Runtime config (URLs, ports) - unchanged
├── root.rb                  # MODIFIED: Add config loading on initialization
├── collection.rb            # MODIFIED: Add config accessor, use config in metadata_files
├── node.rb                  # MODIFIED: Add config accessor, use config in _load_base_attributes
└── path.rb                  # EXISTING: Used for file discovery - unchanged

test/
├── unit/
│   ├── config_loader_test.rb       # NEW: Test file discovery and parsing
│   ├── config_hierarchy_test.rb    # NEW: Test precedence resolution
│   ├── config_validator_test.rb    # NEW: Test validation logic
│   └── config_dsl_test.rb          # NEW: Test Ruby DSL (P4)
├── integration/
│   ├── hierarchical_config_test.rb # NEW: Test root->collection->node flow
│   ├── config_structure_pref_test.rb # NEW: Test structure preference behavior
│   └── config_merge_behavior_test.rb # NEW: Test enable_merge toggle
└── fixtures/
    └── hierarchical_config/        # NEW: Test fixtures with sample .ro.yml/.ro.rb
```

**Structure Decision**: Single library project following existing Ro codebase patterns. New classes in `lib/ro/` namespace. Tests mirror source structure with unit/ and integration/ separation. Existing classes (Root, Collection, Node) modified minimally to integrate config system.

## Complexity Tracking

*No constitutional violations to justify.*

This feature adds straightforward hierarchical configuration following established patterns in the Ruby ecosystem (similar to Rails config, Bundler config). Complexity is inherent to the requirement (3-level hierarchy with 2 formats), not design choice.

## Phase 0: Research & Decisions

**Status**: Research tasks identified, agents will be dispatched

### Research Tasks

1. **Ruby DSL Patterns**: Research best practices for instance_eval-based DSLs
   - Goal: Design intuitive `.ro.rb` syntax
   - Examples to study: Sinatra, Rake, Bundler Gemfile DSL
   - Output: DSL design decisions in research.md

2. **Config File Discovery**: Research directory walking patterns for config files
   - Goal: Efficient discovery of `.ro.{yml,rb}` walking up directory tree
   - Consider: Caching, performance, error handling
   - Output: Discovery algorithm design in research.md

3. **Config Merging Strategies**: Research deep merge approaches for hierarchical configs
   - Goal: Proper precedence handling (node > collection > root > defaults)
   - Map gem already available - document best practices for Map.apply
   - Output: Merge strategy in research.md

4. **Validation Patterns**: Research schema validation for Ruby config objects
   - Goal: Catch invalid config early with clear errors
   - Consider: Dry-validation, custom validator, schema objects
   - Output: Validation approach in research.md

5. **Error Handling**: Research best practices for config error messages
   - Goal: Clear, actionable error messages for malformed YAML, invalid values
   - Examples: File path, line number, expected vs actual
   - Output: Error handling strategy in research.md

**Phase 0 Output**: research.md with all decisions documented

## Phase 1: Design & Contracts

**Prerequisites**: research.md complete

### Design Artifacts

1. **data-model.md**: Document config entities
   - ConfigLoader: File discovery and parsing
   - ConfigHierarchy: Precedence resolution
   - ConfigDSL: Ruby DSL evaluation
   - ConfigValidator: Schema and value validation
   - Default config values
   - Config key registry (structure, enable_merge, etc.)

2. **contracts/**: API contracts
   - Root#config accessor contract
   - Collection#config accessor contract
   - Node#config accessor contract
   - ConfigLoader.load(path) contract
   - ConfigHierarchy#resolve contract
   - Config introspection methods

3. **quickstart.md**: Usage examples
   - Creating .ro.yml at root
   - Overriding at collection level
   - Using .ro.rb for dynamic config
   - Inspecting effective config
   - Common configuration patterns

### Integration Points

- **Root**: Load root-level config on initialization
- **Collection**: Load collection-level config, merge with root config
- **Node**: Load node-level config, merge with collection + root
- **Collection#metadata_files**: Respect `structure` config preference
- **Node#_load_base_attributes**: Respect `enable_merge` config

**Phase 1 Output**: data-model.md, contracts/, quickstart.md, updated agent context

## Implementation Priorities

Following spec priorities (P1 → P4):

### P1: Root-Level Static Configuration
- Implement ConfigLoader for .ro.yml discovery and parsing
- Implement basic ConfigHierarchy with defaults
- Integrate with Root class
- Expose Root#config accessor
- Support `structure` setting (new/old/dual)

### P2: Collection-Level Override
- Extend ConfigLoader to walk up directory tree
- Enhance ConfigHierarchy precedence resolution
- Integrate with Collection class
- Expose Collection#config accessor
- Verify collection config overrides root config

### P3: Node-Level Override
- Complete ConfigLoader for three-level discovery
- Finalize ConfigHierarchy with node precedence
- Integrate with Node class
- Expose Node#config accessor
- Support `merge_attributes` node-level setting

### P4: Ruby DSL Configuration
- Implement ConfigDSL with instance_eval
- Support .ro.rb file evaluation
- Add hook support (before_load, etc.)
- Precedence: .ro.rb > .ro.yml at same level
- Dynamic config based on ENV vars

## Risk Assessment

### Low Risk
- YAML parsing (stdlib, well-tested)
- Map merging (existing dependency, proven in attribute merging)
- File discovery (existing Path class provides patterns)

### Medium Risk
- Ruby DSL safety (need to evaluate in controlled context)
- Performance impact (need to measure config load time)
- Backward compatibility (ensure no config = no behavior change)

### Mitigation
- Comprehensive integration tests for all user scenarios
- Performance benchmarks for config loading
- Explicit defaults when no config present
- Staged rollout (P1-P2 first, P3-P4 later)

## Success Metrics

From spec success criteria:

- SC-001: Single config value switches structure ✓ (verify in tests)
- SC-002: Collection override in <1 minute ✓ (user workflow timing)
- SC-003: <10ms per config level ✓ (performance benchmarks)
- SC-004: 100% invalid syntax caught ✓ (validation test coverage)
- SC-005: Inspect effective config ✓ (API contract tests)
- SC-006: Immediate effect on reinit ✓ (integration tests)
- SC-007: 90%+ DSL intuitive ✓ (user feedback, code review)

## Next Steps

1. Run Phase 0 research agents
2. Consolidate findings in research.md
3. Execute Phase 1 design (data-model, contracts, quickstart)
4. Update agent context with new technical details
5. Ready for /speckit.tasks to generate implementation tasks
