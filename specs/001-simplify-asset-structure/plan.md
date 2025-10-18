# Implementation Plan: Simplify Asset Directory Structure

**Branch**: `001-simplify-asset-structure` | **Date**: 2025-10-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-simplify-asset-structure/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Refactor the ro gem's asset directory structure from nested format (`identifier/attributes.yml` + `identifier/assets/`) to a flattened format (`identifier.yml` + `identifier/`). This breaking change (v4.x → v5.0) simplifies the directory hierarchy by one level, making asset organization more intuitive. Implementation requires modifying core Node, Collection, and Asset classes, creating a migration tool, and establishing comprehensive test coverage (currently no tests exist).

## Technical Context

**Language/Version**: Ruby 3.0+
**Primary Dependencies**: map (~> 6.6), kramdown (~> 2.4), front_matter_parser (~> 1.0), nokogiri (~> 1)
**Storage**: File system (YAML/JSON/TOML metadata files + asset directories)
**Testing**: Custom test runner via Rake (test/unit, test/functional, test/integration)
**Target Platform**: Cross-platform (Linux, macOS, Windows) - Ruby gem
**Project Type**: Single project (Ruby gem library + CLI tool)
**Performance Goals**: <100ms asset lookup for collections with 10,000 assets (per spec SC-001)
**Constraints**: Zero data loss during migration (per spec SC-002), backward compatibility preference for old structure until migration
**Scale/Scope**: Codebase has ~10 core classes, 10+ example assets in public/ro/, breaking change affects all ro users

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: SKIPPED - No project constitution file found at `.specify/memory/constitution.md`. This feature proceeds without constitutional constraints.

**Note**: If this project adopts a constitution in the future, this feature should be reviewed against those principles.

## Project Structure

### Documentation (this feature)

```
specs/[###-feature]/
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
├── node.rb              # MODIFY: Core node class - loads attributes, manages assets
├── collection.rb        # MODIFY: Collection class - discovers nodes by new pattern
├── asset.rb            # MODIFY: Asset class - path resolution for new structure
├── root.rb             # MINOR: May need updates for collection discovery
├── methods.rb          # REVIEW: URL generation, may need path updates
├── path.rb             # REVIEW: Path utilities, may need helpers
├── template.rb         # NO CHANGE: Template rendering (md, yml, etc)
├── script/
│   └── migrator.rb     # NEW: Migration script for old → new structure
└── ... (other files unchanged)

test/                   # NEW: Test directory (currently doesn't exist)
├── unit/
│   ├── node_test.rb    # NEW: Unit tests for Node class
│   ├── collection_test.rb  # NEW: Unit tests for Collection class
│   ├── asset_test.rb   # NEW: Unit tests for Asset class
│   └── migrator_test.rb    # NEW: Unit tests for migration tool
├── integration/
│   └── ro_integration_test.rb  # NEW: End-to-end tests
└── fixtures/           # NEW: Test data in both old and new structures
    ├── old_structure/
    └── new_structure/

public/ro/              # MIGRATE: Example content (test migration here)
├── posts/
│   └── almost-died-in-an-ice-cave.yml  # MIGRATED: Was attributes.yml
│   └── almost-died-in-an-ice-cave/     # MIGRATED: Was assets/ + other files
│       ├── body.md
│       ├── image1.png
│       └── og.jpg
└── ... (other collections migrated similarly)
```

**Structure Decision**: Single project (Ruby gem). This is a library that provides both programmatic API and CLI interface. The core logic lives in `lib/ro/`, with the main entry point at `lib/ro.rb`. Tests will be created in a new `test/` directory following the Rake test convention (unit, functional, integration). The `public/ro/` directory contains example content that will be migrated as part of this feature implementation.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**Status**: N/A - No constitution defined, no violations to track.

