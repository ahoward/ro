#!/usr/bin/env ruby
# Unit tests for Ro::Migrator with asset structure migration

require_relative '../test_helper'

class MigratorTest < RoTestCase
  def setup
    @old_root = Ro::Root.new(old_structure_path)
    @temp_dir = create_temp_dir('migration_test')

    # Copy old structure fixtures to temp for migration testing
    FileUtils.cp_r(old_structure_path.to_s + '/.', @temp_dir.to_s)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && @temp_dir.exist?
  end

  # T042: Test Migrator#initialize
  def test_initialize_with_root_path
    migrator = Ro::Migrator.new(@temp_dir)

    assert_not_nil migrator, "Migrator should be created"
    assert_equal @temp_dir.to_s, migrator.root_path.to_s, "Migrator should store root path"
  end

  def test_initialize_with_options
    migrator = Ro::Migrator.new(@temp_dir, dry_run: true, backup: true, verbose: true)

    assert migrator.dry_run?, "Migrator should be in dry-run mode"
    assert migrator.backup?, "Migrator should have backup enabled"
    assert migrator.verbose?, "Migrator should be verbose"
  end

  # T043: Test Migrator#validate detecting old structure
  def test_validate_detects_old_structure
    migrator = Ro::Migrator.new(@temp_dir)
    result = migrator.validate

    assert result[:has_old_structure], "Should detect old structure"
    assert result[:old_nodes].any?, "Should find old structure nodes"
  end

  # T044: Test Migrator#validate detecting new structure
  def test_validate_detects_new_structure
    new_dir = create_temp_dir('new_structure_test')
    FileUtils.cp_r(new_structure_path.to_s + '/.', new_dir.to_s)

    migrator = Ro::Migrator.new(new_dir)
    result = migrator.validate

    assert result[:has_new_structure], "Should detect new structure"
    assert result[:new_nodes].any?, "Should find new structure nodes"

    FileUtils.rm_rf(new_dir)
  end

  # T045: Test Migrator#preview generating migration plan
  def test_preview_generates_migration_plan
    migrator = Ro::Migrator.new(@temp_dir)
    plan = migrator.preview

    assert plan.is_a?(Array), "Preview should return array of migration steps"
    assert plan.any?, "Preview should have migration steps"

    # Check that plan includes details about what will be migrated
    first_step = plan.first
    assert first_step.key?(:node_id), "Step should include node_id"
    assert first_step.key?(:old_path), "Step should include old_path"
    assert first_step.key?(:new_metadata_file), "Step should include new_metadata_file"
    assert first_step.key?(:new_asset_dir), "Step should include new_asset_dir"
  end

  # T046: Test Migrator#migrate_node for single node
  def test_migrate_node_single_node
    migrator = Ro::Migrator.new(@temp_dir)
    posts_dir = @temp_dir / 'posts'
    old_node_dir = posts_dir / 'sample-post'

    result = migrator.migrate_node('posts', 'sample-post')

    assert result[:success], "Migration should succeed"

    # Check new structure was created
    metadata_file = posts_dir / 'sample-post.yml'
    asset_dir = posts_dir / 'sample-post'

    assert metadata_file.exist?, "Metadata file should exist at collection level"
    assert asset_dir.directory?, "Asset directory should exist"

    # Check old structure was removed
    old_attributes_file = asset_dir / 'attributes.yml'
    old_assets_dir = asset_dir / 'assets'

    assert !old_attributes_file.exist?, "Old attributes.yml should be removed"
    assert !old_assets_dir.exist?, "Old assets/ directory should be removed"
  end

  # T047: Test Migrator#migrate_collection for entire collection
  def test_migrate_collection
    migrator = Ro::Migrator.new(@temp_dir)

    result = migrator.migrate_collection('posts')

    assert result[:success], "Collection migration should succeed"
    assert result[:migrated_count] > 0, "Should migrate at least one node"
  end

  # T048: Test Migrator#migrate for full migration
  def test_migrate_full_root
    migrator = Ro::Migrator.new(@temp_dir)

    result = migrator.migrate

    assert result[:success], "Full migration should succeed"
    assert result[:collections_migrated] > 0, "Should migrate at least one collection"
    assert result[:nodes_migrated] > 0, "Should migrate at least one node"
  end

  # T049: Test Migrator#backup creating backup
  def test_backup_creates_backup
    migrator = Ro::Migrator.new(@temp_dir, backup: true)

    backup_path = migrator.backup

    assert backup_path.exist?, "Backup should be created"
    assert backup_path.to_s.include?('.backup.'), "Backup should have .backup. in name"
  end

  # T050: Test Migrator#rollback restoring from backup
  def test_rollback_restores_from_backup
    migrator = Ro::Migrator.new(@temp_dir, backup: true)

    # Create backup, migrate, then rollback
    backup_path = migrator.backup
    migrator.migrate
    result = migrator.rollback

    assert result[:success], "Rollback should succeed"
    assert result[:restored_from].to_s == backup_path.to_s, "Should restore from backup"
  end
end

# Run the tests
if __FILE__ == $0
  test = MigratorTest.new

  puts "Running Migrator unit tests..."

  tests = [
    :test_initialize_with_root_path,
    :test_initialize_with_options,
    :test_validate_detects_old_structure,
    :test_validate_detects_new_structure,
    :test_preview_generates_migration_plan,
    :test_migrate_node_single_node,
    :test_migrate_collection,
    :test_migrate_full_root,
    :test_backup_creates_backup,
    :test_rollback_restores_from_backup
  ]

  tests.each do |test_method|
    begin
      test.setup
      test.send(test_method)
      test.teardown
      puts "✓ #{test_method}"
    rescue => e
      puts "✗ #{test_method}: #{e.message}"
      puts "  #{e.backtrace.first}"
      test.teardown rescue nil
    end
  end
end
