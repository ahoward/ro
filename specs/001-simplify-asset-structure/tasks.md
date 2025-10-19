# Tasks: Simplify Asset Directory Structure

**Input**: Design documents from `/specs/001-simplify-asset-structure/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are included per TDD approach - this feature creates comprehensive test coverage for a codebase that currently has no tests.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- **Ruby gem**: `lib/ro/`, `test/` at repository root
- Test fixtures in `test/fixtures/`
- Public examples in `public/ro/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, test infrastructure, and basic structure

- [X] T001 Create test directory structure: test/unit/, test/integration/, test/fixtures/
- [X] T002 [P] Create test fixtures directory with subdirectories: test/fixtures/old_structure/ and test/fixtures/new_structure/
- [X] T003 [P] Create test helper file test/test_helper.rb with common setup and assertions
- [X] T004 [P] Update Rakefile to enable test tasks (verify test/**/*_test.rb pattern works)
- [X] T005 [P] Create .gitignore entries for test artifacts: test/tmp/, *.log, .backup.*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Test fixtures and baseline tests that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 [P] Create old structure test fixture in test/fixtures/old_structure/posts/sample-post/ with attributes.yml, body.md, and assets/image.jpg
- [X] T007 [P] Create new structure test fixture in test/fixtures/new_structure/posts/ with sample-post.yml and sample-post/body.md
- [X] T008 [P] Create test fixture with metadata-only node (no asset directory) in test/fixtures/new_structure/posts/metadata-only.yml
- [X] T009 [P] Create test fixture with nested assets in test/fixtures/new_structure/posts/nested-test/ with subdirectory/image.png
- [X] T010 [P] Create test fixture with multiple metadata formats: test/fixtures/new_structure/mixed/test.yml, test.json

**Checkpoint**: ✓ Test fixtures ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Read Asset Data (Priority: P1) 🎯 MVP

**Goal**: Enable reading assets from the new simplified structure (identifier.yml + identifier/ directory)

**Independent Test**: Create an asset with new structure and verify metadata loads from identifier.yml and assets load from identifier/ directory

### Tests for User Story 1

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T011 [P] [US1] Create unit test for Collection#metadata_files in test/unit/collection_test.rb
- [ ] T012 [P] [US1] Create unit test for Collection#each with new structure in test/unit/collection_test.rb
- [ ] T013 [P] [US1] Create unit test for Node initialization with metadata_file parameter in test/unit/node_test.rb
- [ ] T014 [P] [US1] Create unit test for Node#id derived from metadata filename in test/unit/node_test.rb
- [ ] T015 [P] [US1] Create unit test for Node#asset_dir returning node directory (not assets/ subdirectory) in test/unit/node_test.rb
- [ ] T016 [P] [US1] Create unit test for Node#_load_base_attributes loading from external metadata file in test/unit/node_test.rb
- [ ] T017 [P] [US1] Create unit test for Asset path resolution without assets/ prefix in test/unit/asset_test.rb
- [ ] T018 [US1] Create integration test for loading collection with new structure in test/integration/ro_integration_test.rb
- [ ] T019 [US1] Create integration test for metadata-only nodes (FR-007) in test/integration/ro_integration_test.rb

### Implementation for User Story 1

- [ ] T020 [US1] Modify Collection#each in lib/ro/collection.rb to discover nodes by metadata files (.yml, .yaml, .json) instead of subdirectories
- [ ] T021 [US1] Add Collection#metadata_files method in lib/ro/collection.rb to scan for *.{yml,yaml,json,toml} files
- [ ] T022 [US1] Modify Collection#node_for in lib/ro/collection.rb to find nodes by metadata filename instead of directory name
- [ ] T023 [US1] Update Node#initialize in lib/ro/node.rb to accept (collection, metadata_file) parameters instead of (collection, node_directory)
- [ ] T024 [US1] Add Node#metadata_file attribute in lib/ro/node.rb to store path to metadata file
- [ ] T025 [US1] Update Node#id in lib/ro/node.rb to derive from metadata filename (without extension) instead of directory name
- [ ] T026 [US1] Modify Node#_load_base_attributes in lib/ro/node.rb to load from @metadata_file instead of searching for attributes.yml in @path
- [ ] T027 [US1] Update Node#asset_dir in lib/ro/node.rb to return @path (node directory) instead of @path/assets/
- [ ] T028 [US1] Update Node#_ignored_files in lib/ro/node.rb to remove assets/**/** from ignore list and add *.yml/*.json/*.toml (metadata files)
- [ ] T029 [US1] Modify Asset initialization in lib/ro/asset.rb to split paths on node ID instead of /assets/ segment
- [ ] T030 [US1] Update Asset#relative_path calculation in lib/ro/asset.rb for new structure (no assets/ prefix to strip)
- [ ] T031 [US1] Run all US1 tests and verify they pass

**Checkpoint**: At this point, User Story 1 should be fully functional - assets can be read from new structure

---

## Phase 4: User Story 2 - Write Asset Data (Priority: P2)

**Goal**: Enable creating and updating assets in the new structure

**Independent Test**: Create a new asset programmatically, update its metadata, and verify structure matches identifier.yml + identifier/ pattern

### Tests for User Story 2

- [ ] T032 [P] [US2] Create unit test for Node#update_attributes! writing to correct metadata file in test/unit/node_test.rb
- [ ] T033 [P] [US2] Create unit test for creating new node with metadata file in test/unit/node_test.rb
- [ ] T034 [P] [US2] Create integration test for creating new asset in new structure in test/integration/ro_integration_test.rb
- [ ] T035 [P] [US2] Create integration test for updating existing node metadata in test/integration/ro_integration_test.rb
- [ ] T036 [P] [US2] Create integration test for adding assets to existing node in test/integration/ro_integration_test.rb

### Implementation for User Story 2

- [ ] T037 [US2] Update Node#update_attributes! in lib/ro/node.rb to save to @metadata_file instead of @path/attributes.yml
- [ ] T038 [US2] Verify Node can create new metadata files at collection level (test with new node creation)
- [ ] T039 [US2] Verify Asset files can be added to node directory (test file copy to asset_dir)
- [ ] T040 [US2] Test metadata format support (.yml, .json) - verify both formats work for read/write
- [ ] T041 [US2] Run all US2 tests and verify they pass

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - assets can be read AND written in new structure

---

## Phase 5: User Story 3 - Migrate Existing Assets (Priority: P3)

**Goal**: Provide migration tool to convert from old structure to new structure without data loss

**Independent Test**: Create assets in old format, run migration, verify all data is preserved in new format and old structure is removed

### Tests for User Story 3

- [ ] T042 [P] [US3] Create unit test for Migrator#initialize in test/unit/migrator_test.rb
- [ ] T043 [P] [US3] Create unit test for Migrator#validate detecting old structure in test/unit/migrator_test.rb
- [ ] T044 [P] [US3] Create unit test for Migrator#validate detecting new structure in test/unit/migrator_test.rb
- [ ] T045 [P] [US3] Create unit test for Migrator#preview generating migration plan in test/unit/migrator_test.rb
- [ ] T046 [P] [US3] Create unit test for Migrator#migrate moving attributes.yml to identifier.yml in test/unit/migrator_test.rb
- [ ] T047 [P] [US3] Create unit test for Migrator#migrate moving assets/ files to identifier/ in test/unit/migrator_test.rb
- [ ] T048 [P] [US3] Create unit test for Migrator#migrate preserving nested asset directories in test/unit/migrator_test.rb
- [ ] T049 [P] [US3] Create unit test for Migrator#backup creating timestamped backup in test/unit/migrator_test.rb
- [ ] T050 [P] [US3] Create unit test for Migrator#rollback restoring from backup in test/unit/migrator_test.rb
- [ ] T051 [US3] Create integration test for full collection migration in test/integration/ro_integration_test.rb
- [ ] T052 [US3] Create integration test for migration with nested assets in test/integration/ro_integration_test.rb
- [ ] T053 [US3] Create integration test for migration error handling and recovery in test/integration/ro_integration_test.rb

### Implementation for User Story 3

- [ ] T054 [US3] Create lib/ro/script/migrator.rb with Migrator class skeleton
- [ ] T055 [US3] Implement Migrator#initialize in lib/ro/script/migrator.rb with path and options (dry_run, backup, force, verbose)
- [ ] T056 [US3] Implement Migrator#validate in lib/ro/script/migrator.rb to check for old/new/mixed structures
- [ ] T057 [US3] Implement Migrator#preview in lib/ro/script/migrator.rb to generate migration plan (dry run)
- [ ] T058 [US3] Implement Migrator#backup in lib/ro/script/migrator.rb to create timestamped backup using FileUtils.cp_r
- [ ] T059 [US3] Implement Migrator#migrate_node in lib/ro/script/migrator.rb to migrate single node (move attributes.yml, move assets/, cleanup)
- [ ] T060 [US3] Implement Migrator#migrate in lib/ro/script/migrator.rb to iterate all nodes and migrate each
- [ ] T061 [US3] Implement Migrator#rollback in lib/ro/script/migrator.rb to restore from backup
- [ ] T062 [US3] Add error handling and recovery logic to Migrator#migrate in lib/ro/script/migrator.rb
- [ ] T063 [US3] Create CLI command 'ro migrate' in bin/ro or add Rake task for migration
- [ ] T064 [US3] Add migration logging with detailed progress output
- [ ] T065 [US3] Run all US3 tests and verify they pass

**Checkpoint**: All user stories should now be independently functional - read, write, and migrate all work

---

## Phase 6: Integration & Validation

**Purpose**: Ensure all user stories work together and with existing codebase

- [ ] T066 [P] Test that old structure still works if present (backward compatibility during transition)
- [ ] T067 [P] Test mixed structure detection (both old and new for same identifier) raises appropriate error/warning
- [ ] T068 Test full workflow: migrate public/ro/ examples, verify builder/server still work
- [ ] T069 [P] Create integration test for Root → Collection → Node chain with new structure
- [ ] T070 [P] Create integration test for multiple metadata formats (.yml, .json) in same collection
- [ ] T071 Verify performance: test asset lookup speed with 100+ nodes (target <100ms per SC-001)
- [ ] T072 Run existing examples through new code (if any example code exists in repo)

---

## Phase 7: Example Migration & Documentation

**Purpose**: Migrate example content and update documentation

- [ ] T073 Create backup of public/ro/ before migration: cp -r public/ro public/ro.backup.pre-v5
- [ ] T074 Run migration on public/ro/posts/ using the migration tool
- [ ] T075 Run migration on public/ro/pages/ using the migration tool
- [ ] T076 Run migration on public/ro/nerd/ using the migration tool
- [ ] T077 Verify all migrated examples load correctly via ro console
- [ ] T078 [P] Update README.md with new structure examples and migration instructions
- [ ] T079 [P] Create MIGR ATION_GUIDE.md with step-by-step migration instructions
- [ ] T080 [P] Update CHANGELOG.md with breaking changes for v5.0.0
- [ ] T081 [P] Update gem version in lib/ro.rb from 4.4.0 to 5.0.0

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup and verification

- [ ] T082 [P] Add inline documentation (YARD comments) to modified methods in lib/ro/node.rb
- [ ] T083 [P] Add inline documentation to new Migrator class in lib/ro/script/migrator.rb
- [ ] T084 [P] Add inline documentation to modified Collection methods in lib/ro/collection.rb
- [ ] T085 Run all tests (rake test) and ensure 100% pass
- [ ] T086 Validate quickstart.md examples work with new structure
- [ ] T087 [P] Code cleanup: remove any debug logging or commented-out old code
- [ ] T088 [P] Verify .gitignore covers all test artifacts and backup directories
- [ ] T089 Final integration test: build static API with ro builder, verify output matches expectations
- [ ] T090 Performance benchmark: measure asset lookup time with 1000+ nodes, verify <100ms (SC-001)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 (Read) → Can start immediately after Foundational
  - US2 (Write) → Can start immediately after Foundational, but logically should follow US1
  - US3 (Migrate) → Can start immediately after Foundational, but logically should follow US1+US2 since it needs to verify both reading and writing work
- **Integration (Phase 6)**: Depends on all user stories (US1, US2, US3)
- **Examples & Docs (Phase 7)**: Depends on US3 (migration tool) being complete
- **Polish (Phase 8)**: Depends on all previous phases

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Logically depends on US1 (need to read before write), but could be developed in parallel
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Logically depends on US1+US2 (needs to verify both work), but could be developed in parallel

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Tests can run in parallel (all marked [P])
- Implementation tasks run sequentially (Collection → Node → Asset) due to dependencies
- Each story must be complete and independently testable before moving to next priority

### Parallel Opportunities

- **Setup tasks**: T002, T003, T004, T005 can run in parallel
- **Foundational fixtures**: T006-T010 can all run in parallel
- **US1 tests**: T011-T017, T019 can run in parallel (T018 may depend on others)
- **US2 tests**: T032-T036 can all run in parallel
- **US3 tests**: T042-T050, T052, T053 can run in parallel
- **Integration tests**: T066, T067, T069, T070 can run in parallel
- **Documentation**: T078-T084 can run in parallel
- **Polish**: T082-T084, T087, T088 can run in parallel

### Sequential Requirements

- T020-T030 (US1 implementation) must run in order due to class dependencies
- T037-T040 (US2 implementation) must run in order
- T054-T065 (US3 implementation) must run in order
- T073-T077 (example migration) must run in order (backup before migrate)

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all US1 unit tests together:
Task: "Create unit test for Collection#metadata_files in test/unit/collection_test.rb"
Task: "Create unit test for Collection#each with new structure in test/unit/collection_test.rb"
Task: "Create unit test for Node initialization with metadata_file parameter in test/unit/node_test.rb"
Task: "Create unit test for Node#id derived from metadata filename in test/unit/node_test.rb"
Task: "Create unit test for Node#asset_dir returning node directory in test/unit/node_test.rb"
Task: "Create unit test for Asset path resolution without assets/ prefix in test/unit/asset_test.rb"
```

---

## Parallel Example: User Story 3 Tests

```bash
# Launch all US3 unit tests together:
Task: "Create unit test for Migrator#initialize in test/unit/migrator_test.rb"
Task: "Create unit test for Migrator#validate detecting old structure in test/unit/migrator_test.rb"
Task: "Create unit test for Migrator#preview generating migration plan in test/unit/migrator_test.rb"
Task: "Create unit test for Migrator#backup creating timestamped backup in test/unit/migrator_test.rb"
Task: "Create unit test for Migrator#rollback restoring from backup in test/unit/migrator_test.rb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T010) - CRITICAL
3. Complete Phase 3: User Story 1 (T011-T031)
4. **STOP and VALIDATE**: Run all US1 tests, verify assets load from new structure
5. This gives you a working MVP that can read assets in the new simplified format

### Incremental Delivery

1. Complete Setup + Foundational → Test infrastructure ready
2. Add User Story 1 (Read) → Test independently → MVP working! Can read new structure
3. Add User Story 2 (Write) → Test independently → Can create/update assets in new structure
4. Add User Story 3 (Migrate) → Test independently → Can migrate old data to new structure
5. Complete Integration, Examples, Polish → Production ready for v5.0.0 release

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup (Phase 1) + Foundational (Phase 2) together
2. Once Foundational is done:
   - Developer A: User Story 1 (Read) - T011-T031
   - Developer B: User Story 2 (Write) - T032-T041 (may need to wait for some US1 completion)
   - Developer C: User Story 3 (Migrate) - T042-T065
3. Stories complete and integrate independently
4. Team collaborates on Integration (Phase 6) and Polish (Phases 7-8)

### TDD Workflow (Required for this feature)

This feature follows strict TDD due to zero existing test coverage:

1. **Red**: Write tests first (T011-T019 for US1)
2. **Verify Red**: Run tests, ensure they FAIL (proves tests are testing something)
3. **Green**: Implement code (T020-T030 for US1)
4. **Verify Green**: Run tests, ensure they PASS
5. **Refactor**: Clean up code while keeping tests green
6. **Repeat** for each user story

---

## Notes

- [P] tasks = different files, no dependencies - can run in parallel
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD approach)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- **CRITICAL**: This is a breaking change (v4.x → v5.0.0) - all existing ro users must migrate their data
- **Performance target**: <100ms asset lookup for 10,000 assets (SC-001)
- **Migration requirement**: Zero data loss (SC-002)
- Backward compatibility: Old structure should still work during transition period (FR-011)

---

## Task Count Summary

- **Total Tasks**: 90
- **Setup (Phase 1)**: 5 tasks
- **Foundational (Phase 2)**: 5 tasks
- **User Story 1 (Phase 3)**: 21 tasks (9 tests + 12 implementation)
- **User Story 2 (Phase 4)**: 10 tasks (5 tests + 5 implementation)
- **User Story 3 (Phase 5)**: 24 tasks (12 tests + 12 implementation)
- **Integration (Phase 6)**: 7 tasks
- **Examples & Docs (Phase 7)**: 9 tasks
- **Polish (Phase 8)**: 9 tasks

**Parallel Opportunities**: 40+ tasks can run in parallel (marked with [P])

**MVP Scope**: Phases 1-3 only (31 tasks) delivers working read capability with new structure

**Full Feature**: All 90 tasks delivers complete v5.0.0 with read, write, migrate, tests, examples, and documentation
