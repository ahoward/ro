# Tasks: Hierarchical Configuration System

**Input**: Design documents from `/specs/002-hierarchical-config/`
**Prerequisites**: spec.md ✓, plan.md ✓, research.md ✓

**Tests**: Tests are included (Ro uses TDD - tests first, then implementation)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions
- Single library project: `lib/ro/`, `test/` at repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create new classes structure in lib/ro/ for config system
- [ ] T002 Add Map deep_merge extension to lib/ro/core_ext/map.rb
- [ ] T003 [P] Create test fixtures directory at test/fixtures/hierarchical_config/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Implement Ro::ConfigLoader class in lib/ro/config_loader.rb for discovering and loading .ro.yml files
- [ ] T005 [P] Implement Ro::ConfigValidator class in lib/ro/config_validator.rb for schema validation
- [ ] T006 [P] Implement Ro::ConfigHierarchy class in lib/ro/config_hierarchy.rb for precedence resolution
- [ ] T007 [P] Extend Ro::Error with config-specific exception classes in lib/ro/error.rb
- [ ] T008 Create default config schema with structure, enable_merge, and other settings
- [ ] T009 Add config accessor methods to Ro module in lib/ro.rb

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Root-Level Static Configuration (Priority: P1) 🎯 MVP

**Goal**: Enable global configuration for entire Ro repository via .ro.yml at root level

**Independent Test**: Create .ro.yml at root with structure preference, load Ro::Root, verify collections respect configured behavior

### Tests for User Story 1 (TDD - Write First)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T010 [P] [US1] Unit test for ConfigLoader.load_file in test/unit/config_loader_test.rb
- [ ] T011 [P] [US1] Unit test for ConfigValidator.validate! in test/unit/config_validator_test.rb
- [ ] T012 [P] [US1] Unit test for ConfigHierarchy with defaults in test/unit/config_hierarchy_test.rb
- [ ] T013 [US1] Integration test for root-level config discovery in test/integration/root_config_test.rb
- [ ] T014 [US1] Integration test for structure preference (new/old/dual) in test/integration/config_structure_pref_test.rb

### Implementation for User Story 1

- [ ] T015 [US1] Implement ConfigLoader#discover for finding .ro.yml at path in lib/ro/config_loader.rb
- [ ] T016 [US1] Implement ConfigLoader#load_file for parsing YAML safely in lib/ro/config_loader.rb
- [ ] T017 [US1] Implement ConfigValidator with SCHEMA for structure, enable_merge in lib/ro/config_validator.rb
- [ ] T018 [US1] Implement ConfigValidator#validate! with type coercion in lib/ro/config_validator.rb
- [ ] T019 [US1] Implement ConfigHierarchy#initialize with defaults in lib/ro/config_hierarchy.rb
- [ ] T020 [US1] Add Root#config accessor that loads root-level config in lib/ro/root.rb
- [ ] T021 [US1] Add Root#initialize config loading with error handling in lib/ro/root.rb
- [ ] T022 [US1] Modify Collection#metadata_files to respect config[:structure] in lib/ro/collection.rb
- [ ] T023 [US1] Add comprehensive error handling with ConfigSyntaxError, ConfigValidationError in lib/ro/error.rb

**Checkpoint**: At this point, User Story 1 should be fully functional - root-level YAML config works

---

## Phase 4: User Story 2 - Collection-Level Configuration Override (Priority: P2)

**Goal**: Enable per-collection configuration so different collections can use different metadata structures

**Independent Test**: Set root config to structure: new, add collection-level .ro.yml with structure: old, verify posts collection uses old structure while others use new

### Tests for User Story 2 (TDD - Write First)

- [ ] T024 [P] [US2] Unit test for ConfigLoader.discover_hierarchy in test/unit/config_loader_test.rb
- [ ] T025 [P] [US2] Unit test for ConfigHierarchy.merge_configs in test/unit/config_hierarchy_test.rb
- [ ] T026 [US2] Integration test for collection-level override in test/integration/collection_config_test.rb
- [ ] T027 [US2] Integration test for "deeper wins" precedence in test/integration/config_precedence_test.rb

### Implementation for User Story 2

- [ ] T028 [US2] Extend ConfigLoader#discover to walk up directory tree in lib/ro/config_loader.rb
- [ ] T029 [US2] Implement ConfigLoader#discover_hierarchy for three levels in lib/ro/config_loader.rb
- [ ] T030 [US2] Implement Map#deep_merge in lib/ro/core_ext/map.rb (NOT Map#apply which has wrong semantics)
- [ ] T031 [US2] Implement ConfigHierarchy#merge for root + collection precedence in lib/ro/config_hierarchy.rb
- [ ] T032 [US2] Add Collection#config accessor with merged config in lib/ro/collection.rb
- [ ] T033 [US2] Add Collection#initialize config loading in lib/ro/collection.rb
- [ ] T034 [US2] Update Collection#metadata_files to use merged config in lib/ro/collection.rb
- [ ] T035 [US2] Add caching for discovered config file paths in lib/ro/config_loader.rb

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - collection overrides work

---

## Phase 5: User Story 3 - Node-Level Configuration Override (Priority: P3)

**Goal**: Enable per-node configuration for fine-grained control of individual posts/pages

**Independent Test**: Create node directory with .ro.yml, set node-specific config, load node, verify setting applies only to that node

### Tests for User Story 3 (TDD - Write First)

- [ ] T036 [P] [US3] Unit test for ConfigHierarchy three-level merge in test/unit/config_hierarchy_test.rb
- [ ] T037 [P] [US3] Integration test for node-level override in test/integration/node_config_test.rb
- [ ] T038 [US3] Integration test for node merge_attributes control in test/integration/config_merge_behavior_test.rb
- [ ] T039 [US3] Integration test for effective config inspection in test/integration/config_introspection_test.rb

### Implementation for User Story 3

- [ ] T040 [US3] Complete ConfigLoader#discover_hierarchy for node level in lib/ro/config_loader.rb
- [ ] T041 [US3] Extend ConfigHierarchy#merge for node + collection + root in lib/ro/config_hierarchy.rb
- [ ] T042 [US3] Add Node#config accessor with fully merged config in lib/ro/node.rb
- [ ] T043 [US3] Add Node#initialize config loading in lib/ro/node.rb
- [ ] T044 [US3] Modify Node#_load_base_attributes to respect config[:enable_merge] in lib/ro/node.rb
- [ ] T045 [US3] Add config introspection methods (raw_config, effective_config) in lib/ro/config_hierarchy.rb
- [ ] T046 [US3] Add ConfigHierarchy#source_trace for debugging which file each setting came from in lib/ro/config_hierarchy.rb

**Checkpoint**: All YAML-based user stories (US1, US2, US3) should now be independently functional

---

## Phase 6: User Story 4 - Ruby DSL Configuration (Priority: P4)

**Goal**: Enable dynamic configuration with Ruby code for advanced use cases

**Independent Test**: Create .ro.rb with DSL code (ENV vars, conditionals), load root, verify dynamic config is applied

### Tests for User Story 4 (TDD - Write First)

- [ ] T047 [P] [US4] Unit test for ConfigDSL evaluation in test/unit/config_dsl_test.rb
- [ ] T048 [P] [US4] Unit test for ConfigDSL error handling in test/unit/config_dsl_test.rb
- [ ] T049 [US4] Integration test for .ro.rb precedence over .ro.yml in test/integration/ruby_config_test.rb
- [ ] T050 [US4] Integration test for before_load/after_load hooks in test/integration/config_hooks_test.rb

### Implementation for User Story 4

- [ ] T051 [US4] Implement Ro::ConfigDSL class in lib/ro/config_dsl.rb with instance_eval
- [ ] T052 [US4] Implement ConfigDSL#before_load hook registration in lib/ro/config_dsl.rb
- [ ] T053 [US4] Implement ConfigDSL#after_load hook registration in lib/ro/config_dsl.rb
- [ ] T054 [US4] Extend ConfigLoader to handle .ro.rb files in lib/ro/config_loader.rb
- [ ] T055 [US4] Implement ConfigLoader#load_ruby_file with safe evaluation in lib/ro/config_loader.rb
- [ ] T056 [US4] Add .ro.rb precedence over .ro.yml at same level in lib/ro/config_loader.rb
- [ ] T057 [US4] Add hook execution in Node#load_attributes! in lib/ro/node.rb
- [ ] T058 [US4] Add Ruby evaluation error handling (SyntaxError, NoMethodError) in lib/ro/error.rb
- [ ] T059 [US4] Add ConfigDSL validation to ensure hooks are callable in lib/ro/config_dsl.rb

**Checkpoint**: All user stories (US1-US4) should now be fully functional

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T060 [P] Add comprehensive documentation to README.md for hierarchical config
- [ ] T061 [P] Create example .ro.yml and .ro.rb files in examples/
- [ ] T062 [P] Add CLI command `ro config show` for introspection in lib/ro/script/config.rb
- [ ] T063 [P] Add performance benchmarks for config loading in test/performance/config_benchmark.rb
- [ ] T064 Code cleanup and refactoring of config classes
- [ ] T065 Add mtime-based cache invalidation for config content in lib/ro/config_loader.rb
- [ ] T066 [P] Update CHANGELOG.md with new configuration system
- [ ] T067 [P] Add migration guide for users moving from old to new structure
- [ ] T068 Security review for .ro.rb evaluation safety
- [ ] T069 Add debug mode with verbose config logging
- [ ] T070 Create quickstart validation script that exercises all config features

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3 → P4)
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Extends US1 but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Extends US2 but independently testable
- **User Story 4 (P4)**: Can start after Foundational (Phase 2) - Adds .ro.rb support, independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD)
- Unit tests before integration tests
- Core classes (ConfigLoader, ConfigValidator) before integration points (Root, Collection, Node)
- Error handling integrated throughout
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T001, T003)
- All Foundational tasks marked [P] can run in parallel (T005, T006, T007)
- Once Foundational phase completes, all user stories CAN start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all unit tests for User Story 1 together:
Task: "Unit test for ConfigLoader.load_file in test/unit/config_loader_test.rb"
Task: "Unit test for ConfigValidator.validate! in test/unit/config_validator_test.rb"
Task: "Unit test for ConfigHierarchy with defaults in test/unit/config_hierarchy_test.rb"

# After tests written and failing, implement in parallel:
Task: "Implement ConfigLoader#discover in lib/ro/config_loader.rb"
Task: "Implement ConfigValidator with SCHEMA in lib/ro/config_validator.rb"
Task: "Implement ConfigHierarchy#initialize in lib/ro/config_hierarchy.rb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T009) - CRITICAL
3. Complete Phase 3: User Story 1 (T010-T023)
4. **STOP and VALIDATE**: Test User Story 1 independently with real .ro.yml files
5. Commit, create PR, deploy if ready

### Incremental Delivery (Recommended)

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (P1) → Test independently → **MVP: Root-level config works!**
3. Add User Story 2 (P2) → Test independently → **Collection overrides work!**
4. Add User Story 3 (P3) → Test independently → **Node-level control works!**
5. Add User Story 4 (P4) → Test independently → **Ruby DSL works!**
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001-T009)
2. Once Foundational is done:
   - Developer A: User Story 1 (T010-T023) - Root config
   - Developer B: User Story 2 (T024-T035) - Collection override
   - Developer C: User Story 3 (T036-T046) - Node override
   - Developer D: User Story 4 (T047-T059) - Ruby DSL
3. Stories complete and integrate independently
4. Integration testing of all stories together

---

## Critical Path (Sequential Implementation)

If implementing sequentially, this is the recommended order:

1. **Foundation** (T001-T009) - ~2-3 hours
   - Cannot parallelize, required for everything

2. **US1: Root Config** (T010-T023) - ~4-6 hours
   - MVP milestone: Basic YAML config works
   - Tests: 5 test files
   - Implementation: 9 tasks

3. **US2: Collection Override** (T024-T035) - ~3-4 hours
   - Tests: 4 test files
   - Implementation: 8 tasks
   - Builds on US1, adds precedence

4. **US3: Node Override** (T036-T046) - ~2-3 hours
   - Tests: 4 test files
   - Implementation: 7 tasks
   - Completes three-level hierarchy

5. **US4: Ruby DSL** (T047-T059) - ~3-4 hours
   - Tests: 4 test files
   - Implementation: 9 tasks
   - Advanced feature, optional

6. **Polish** (T060-T070) - ~2-3 hours
   - Can be spread across user stories

**Total Estimated Time**: 16-23 hours (with sequential implementation)

**With Parallel Team**: Can reduce to 8-12 hours (2x speedup with good coordination)

---

## Test Coverage Requirements

Each user story must have:
- ✅ Unit tests for all new classes
- ✅ Integration tests for user journey
- ✅ Error case coverage (malformed YAML, invalid values, missing files)
- ✅ Edge case tests (empty configs, nil values, type mismatches)

**Total Test Files**: ~17 test files across unit/ and integration/

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- **TDD Required**: Verify tests fail before implementing (Ro's standard practice)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Run full test suite after each user story: `rake test`
- Use existing Ro test patterns (RoTestCase, fixtures, Minitest)

---

## Success Validation

After completing each user story, validate:

- **US1**: Create .ro.yml at root, set `structure: new`, verify Ro::Root loads and respects setting
- **US2**: Add .ro.yml in collection, set different structure, verify collection overrides root
- **US3**: Add .ro.yml in node directory, verify node-specific settings work
- **US4**: Create .ro.rb with ENV vars and hooks, verify dynamic config and hooks execute

**Final Validation**: All 4 user stories working together with mixed .yml and .rb files at all levels

---

## Files Modified/Created Summary

### New Files (16)
- `lib/ro/config_loader.rb` - File discovery and loading
- `lib/ro/config_hierarchy.rb` - Precedence resolution
- `lib/ro/config_validator.rb` - Schema validation
- `lib/ro/config_dsl.rb` - Ruby DSL support
- `lib/ro/core_ext/map.rb` - deep_merge extension
- `test/unit/config_loader_test.rb`
- `test/unit/config_hierarchy_test.rb`
- `test/unit/config_validator_test.rb`
- `test/unit/config_dsl_test.rb`
- `test/integration/root_config_test.rb`
- `test/integration/collection_config_test.rb`
- `test/integration/node_config_test.rb`
- `test/integration/config_structure_pref_test.rb`
- `test/integration/config_precedence_test.rb`
- `test/integration/config_merge_behavior_test.rb`
- `test/integration/ruby_config_test.rb`

### Modified Files (5)
- `lib/ro/root.rb` - Add config accessor and loading
- `lib/ro/collection.rb` - Add config accessor, use in metadata_files
- `lib/ro/node.rb` - Add config accessor, use in _load_base_attributes
- `lib/ro/error.rb` - Add config-specific exceptions
- `lib/ro.rb` - Add module-level config methods

**Total**: 21 files (16 new, 5 modified)
