#!/usr/bin/env ruby
# Unit tests for Ro::Node with new structure support

require_relative '../test_helper'

class NodeTest < RoTestCase
  def setup
    @root = Ro::Root.new(new_structure_path)
    @collection = Ro::Collection.new(new_structure_path / 'posts')
    @metadata_file = new_structure_path / 'posts' / 'sample-post.yml'
  end

  # T013: Test Node initialization with metadata_file parameter
  def test_initialize_with_metadata_file
    node = Ro::Node.new(@collection, @metadata_file)

    assert_not_nil node, "Node should be created"
    assert_equal @collection, node.collection, "Node should store collection reference"
  end

  def test_initialize_stores_metadata_file
    node = Ro::Node.new(@collection, @metadata_file)

    assert_not_nil node.metadata_file, "Node should store metadata_file"
    assert_equal @metadata_file.to_s, node.metadata_file.to_s, "metadata_file path should match constructor parameter"
  end

  def test_initialize_raises_error_for_missing_file
    missing_file = new_structure_path / 'posts' / 'nonexistent.yml'

    assert_raises(Errno::ENOENT) do
      Ro::Node.new(@collection, missing_file)
    end
  end

  # T014: Test Node#id derived from metadata filename
  def test_id_derived_from_metadata_filename
    node = Ro::Node.new(@collection, @metadata_file)

    assert_equal 'sample-post', node.id, "Node ID should be derived from metadata filename (without extension)"
  end

  def test_id_strips_yml_extension
    node = Ro::Node.new(@collection, @metadata_file)

    assert !node.id.end_with?('.yml'), "Node ID should not include .yml extension"
  end

  def test_id_handles_json_extension
    json_file = new_structure_path / 'mixed' / 'test-json.json'
    collection = Ro::Collection.new(new_structure_path / 'mixed')
    node = Ro::Node.new(collection, json_file)

    assert_equal 'test-json', node.id, "Node ID should be derived from .json filename"
    assert !node.id.end_with?('.json'), "Node ID should not include .json extension"
  end

  # T015: Test Node#asset_dir returns node directory (not assets/ subdirectory)
  def test_asset_dir_returns_node_directory
    node = Ro::Node.new(@collection, @metadata_file)
    expected_dir = new_structure_path / 'posts' / 'sample-post'

    assert_equal expected_dir.to_s, node.asset_dir.to_s, "asset_dir should return node directory"
  end

  def test_asset_dir_not_assets_subdirectory
    node = Ro::Node.new(@collection, @metadata_file)

    assert !node.asset_dir.to_s.end_with?('/assets'), "asset_dir should NOT end with /assets"
  end

  def test_asset_dir_for_metadata_only_node
    metadata_only_file = new_structure_path / 'posts' / 'metadata-only.yml'
    node = Ro::Node.new(@collection, metadata_only_file)
    expected_dir = new_structure_path / 'posts' / 'metadata-only'

    # asset_dir should still return the expected path even if directory doesn't exist
    assert_equal expected_dir.to_s, node.asset_dir.to_s
  end

  # T016: Test Node#_load_base_attributes loading from external metadata file
  def test_load_base_attributes_from_metadata_file
    node = Ro::Node.new(@collection, @metadata_file)

    # Trigger attribute loading (happens in initialize)
    attrs = node.attributes

    assert_not_nil attrs, "Attributes should be loaded"
    assert attrs.is_a?(Hash), "Attributes should be a Hash"
  end

  def test_attributes_loaded_from_correct_file
    node = Ro::Node.new(@collection, @metadata_file)

    assert_equal 'Sample Post (New Structure)', node[:title], "Should load title from metadata file"
    assert_equal 'Test Author', node[:author], "Should load author from metadata file"
  end

  def test_attributes_support_symbol_and_string_keys
    node = Ro::Node.new(@collection, @metadata_file)

    # Should work with both symbol and string keys
    assert_equal node[:title], node['title'], "Attributes should work with both symbol and string keys"
  end
end

# Run the tests
if __FILE__ == $0
  test = NodeTest.new

  puts "Running Node unit tests..."

  tests = [
    :test_initialize_with_metadata_file,
    :test_initialize_stores_metadata_file,
    :test_initialize_raises_error_for_missing_file,
    :test_id_derived_from_metadata_filename,
    :test_id_strips_yml_extension,
    :test_id_handles_json_extension,
    :test_asset_dir_returns_node_directory,
    :test_asset_dir_not_assets_subdirectory,
    :test_asset_dir_for_metadata_only_node,
    :test_load_base_attributes_from_metadata_file,
    :test_attributes_loaded_from_correct_file,
    :test_attributes_support_symbol_and_string_keys
  ]

  tests.each do |test_method|
    begin
      test.setup
      test.send(test_method)
      puts "✓ #{test_method}"
    rescue => e
      puts "✗ #{test_method}: #{e.message}"
      puts "  #{e.backtrace.first}"
    end
  end
end
