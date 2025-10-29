# Test Helper for ro gem v5.0 tests
#
# Common setup, assertions, and utilities for unit and integration tests

require 'pathname'
require 'fileutils'
require 'yaml'
require 'json'

# Load the ro gem
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'ro'

module TestHelper
  # Get path to test fixtures directory
  def fixtures_path
    Pathname.new(File.expand_path('../fixtures', __FILE__))
  end

  # Get path to old structure fixtures
  def old_structure_path
    fixtures_path / 'old_structure'
  end

  # Get path to new structure fixtures
  def new_structure_path
    fixtures_path / 'new_structure'
  end

  # Create a temporary test directory
  def create_temp_dir(name = 'test')
    dir = Pathname.new(File.expand_path("../tmp/#{name}_#{Time.now.to_i}", __FILE__))
    FileUtils.mkdir_p(dir)
    dir
  end

  # Clean up temporary directory
  def cleanup_temp_dir(dir)
    FileUtils.rm_rf(dir) if dir && dir.exist?
  end

  # Assert that a path exists
  def assert_path_exists(path, message = nil)
    assert Pathname.new(path).exist?, message || "Expected path to exist: #{path}"
  end

  # Assert that a file contains specific content
  def assert_file_contains(path, content, message = nil)
    actual = File.read(path)
    assert actual.include?(content), message || "Expected file #{path} to contain: #{content}"
  end

  # Assert that a YAML file has a specific key/value
  def assert_yaml_has(path, key, value = nil, message = nil)
    data = YAML.load_file(path)
    assert data.key?(key.to_s) || data.key?(key.to_sym), message || "Expected YAML to have key: #{key}"
    if value
      actual_value = data[key.to_s] || data[key.to_sym]
      assert_equal value, actual_value, message || "Expected #{key} to equal #{value}, got #{actual_value}"
    end
  end

  # Create a test node in old structure format
  def create_old_structure_node(collection_path, node_id, attributes = {}, assets = [])
    node_dir = collection_path / node_id
    FileUtils.mkdir_p(node_dir)
    FileUtils.mkdir_p(node_dir / 'assets')

    # Write attributes.yml
    File.write(node_dir / 'attributes.yml', attributes.to_yaml)

    # Create asset files
    assets.each do |asset_file|
      asset_path = node_dir / 'assets' / asset_file
      FileUtils.mkdir_p(asset_path.dirname)
      File.write(asset_path, "test content for #{asset_file}")
    end

    node_dir
  end

  # Create a test node in new structure format
  def create_new_structure_node(collection_path, node_id, attributes = {}, assets = [])
    FileUtils.mkdir_p(collection_path)

    # Write metadata file (identifier.yml)
    File.write(collection_path / "#{node_id}.yml", attributes.to_yaml)

    # Create asset directory and files
    if assets.any?
      node_dir = collection_path / node_id
      FileUtils.mkdir_p(node_dir)

      assets.each do |asset_file|
        asset_path = node_dir / asset_file
        FileUtils.mkdir_p(asset_path.dirname)
        File.write(asset_path, "test content for #{asset_file}")
      end
    end

    collection_path / "#{node_id}.yml"
  end
end

# Base test class
class RoTestCase
  include TestHelper

  def setup
    # Override in subclasses
  end

  def teardown
    # Override in subclasses
  end

  # Simple assertion methods (compatible with custom test runner)
  def assert(condition, message = "Assertion failed")
    raise AssertionError, message unless condition
  end

  def assert_equal(expected, actual, message = nil)
    msg = message || "Expected #{expected.inspect}, got #{actual.inspect}"
    assert expected == actual, msg
  end

  def assert_nil(actual, message = nil)
    msg = message || "Expected nil, got #{actual.inspect}"
    assert actual.nil?, msg
  end

  def assert_not_nil(actual, message = nil)
    msg = message || "Expected non-nil value"
    assert !actual.nil?, msg
  end

  def assert_raises(exception_class, message = nil)
    begin
      yield
      assert false, message || "Expected #{exception_class} to be raised"
    rescue exception_class
      # Expected
    end
  end

  def skip(message = "Test skipped")
    raise SkipError, message
  end

  class AssertionError < StandardError; end
  class SkipError < StandardError; end
end

puts "Test helper loaded successfully"
