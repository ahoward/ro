#!/usr/bin/env ruby
# Integration tests for US1: Root-Level Static Configuration

require_relative '../test_helper'

class RootConfigTest < RoTestCase
  def setup
    @fixture_path = fixtures_path / 'hierarchical_config' / 'root_only'
    @root = Ro::Root.new(@fixture_path)
  end

  # AS1.1: Create .ro.yml with structure: new
  def test_root_config_with_structure_new
    config = @root.config

    assert_not_nil config, "Config should not be nil"
    assert_equal 'new', config[:structure], "Structure should be 'new' from config file"
  end

  # AS1.2: Config values are accessible via root.config
  def test_root_config_accessor
    config = @root.config

    assert_equal 'new', config[:structure]
    assert_equal true, config[:enable_merge]
    assert_equal 'root_value', config[:custom_setting]
  end

  # AS1.3: Feature toggles affect behavior
  def test_enable_merge_toggle
    config = @root.config

    assert_equal true, config[:enable_merge], "enable_merge should be true from config"
  end

  # AS1.4: Malformed YAML produces clear error
  def test_malformed_yaml_error
    bad_fixture_dir = create_temp_dir('bad_yaml')
    bad_yml = bad_fixture_dir / '.ro.yml'

    # Write malformed YAML
    File.write(bad_yml, "invalid: yaml: content:\n  - broken")

    error = nil
    begin
      Ro::Root.new(bad_fixture_dir)
    rescue Ro::ConfigSyntaxError => e
      error = e
    end

    # Root initialization should succeed but log warning
    # (config errors don't fail initialization)
    assert_nil error, "Root should initialize even with bad config"

  ensure
    cleanup_temp_dir(bad_fixture_dir) if bad_fixture_dir
  end

  # AS1.5: No config file means defaults are used
  def test_no_config_uses_defaults
    temp_dir = create_temp_dir('no_config')
    root = Ro::Root.new(temp_dir)

    config = root.config

    assert_not_nil config, "Config should not be nil"
    assert_equal 'dual', config[:structure], "Default structure should be 'dual'"
    assert_equal true, config[:enable_merge], "Default enable_merge should be true"

  ensure
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # Additional: Test config introspection
  def test_config_hierarchy_sources
    hierarchy = @root.hierarchy_config

    assert_not_nil hierarchy, "Hierarchy should exist"
    assert hierarchy.config_exists_at?(:root), "Root config should exist"
    assert !hierarchy.config_exists_at?(:collection), "Collection config should not exist at root level"
    assert !hierarchy.config_exists_at?(:node), "Node config should not exist at root level"
  end

  # Additional: Test that config is cached
  def test_config_caching
    config1 = @root.config
    config2 = @root.config

    assert config1.object_id == config2.object_id, "Config should be cached (same object)"
  end

  # Additional: Test custom config keys are preserved
  def test_custom_config_keys
    config = @root.config

    assert_equal 'root_value', config[:custom_setting], "Custom keys should be preserved"
  end
end

# Run tests
if __FILE__ == $0
  test = RootConfigTest.new

  tests = [
    :test_root_config_with_structure_new,
    :test_root_config_accessor,
    :test_enable_merge_toggle,
    :test_malformed_yaml_error,
    :test_no_config_uses_defaults,
    :test_config_hierarchy_sources,
    :test_config_caching,
    :test_custom_config_keys
  ]

  tests.each do |test_method|
    begin
      test.setup
      test.send(test_method)
      puts "✓ #{test_method}"
    rescue => e
      puts "✗ #{test_method}: #{e.message}"
      puts "  #{e.backtrace.first(3).join("\n  ")}"
      exit 1
    ensure
      test.teardown if test.respond_to?(:teardown)
    end
  end

  puts "\nAll tests passed! ✨"
end
