#!/usr/bin/env ruby
# Integration tests for Ro with new structure support

require_relative '../test_helper'

class RoIntegrationTest < RoTestCase
  def setup
    @root = Ro::Root.new(new_structure_path)
  end

  # T018: Test loading collection with new structure
  def test_load_collection_with_new_structure
    posts = @root['posts']

    assert_not_nil posts, "Should load posts collection"
    assert posts.is_a?(Ro::Collection), "Should return Collection instance"
  end

  def test_collection_discovers_nodes_from_metadata_files
    posts = @root['posts']
    nodes = posts.nodes

    assert nodes.any?, "Collection should discover nodes"

    # Should find all nodes with metadata files
    node_ids = nodes.map(&:id)
    assert node_ids.include?('sample-post'), "Should find sample-post"
    assert node_ids.include?('metadata-only'), "Should find metadata-only"
    assert node_ids.include?('nested-test'), "Should find nested-test"
  end

  def test_node_loads_metadata_from_external_file
    posts = @root['posts']
    node = posts['sample-post']

    assert_not_nil node, "Should find sample-post node"
    assert_equal 'Sample Post (New Structure)', node[:title], "Should load metadata from identifier.yml"
  end

  def test_node_loads_assets_from_node_directory
    posts = @root['posts']
    node = posts['sample-post']

    asset_paths = node.asset_paths

    assert asset_paths.any?, "Node should have assets"

    # Assets should be in node directory (not assets/ subdirectory)
    asset_paths.each do |path|
      expected_dir = new_structure_path / 'posts' / 'sample-post'
      assert path.to_s.start_with?(expected_dir.to_s), "Assets should be in node directory"
      assert !path.to_s.include?('/assets/'), "Asset paths should not contain /assets/ subdirectory"
    end
  end

  def test_nested_assets_preserved
    posts = @root['posts']
    node = posts['nested-test']

    asset_paths = node.asset_paths

    # Should find nested asset
    nested_asset = asset_paths.find { |p| p.to_s.include?('subdirectory/image.png') }
    assert_not_nil nested_asset, "Should find nested asset in subdirectory"
  end

  def test_multiple_collections
    posts = @root['posts']
    mixed = @root['mixed']

    assert_not_nil posts, "Should load posts collection"
    assert_not_nil mixed, "Should load mixed collection"

    assert posts.nodes.size > 0, "Posts should have nodes"
    assert mixed.nodes.size > 0, "Mixed should have nodes"
  end

  def test_multiple_metadata_formats
    mixed = @root['mixed']
    nodes = mixed.nodes

    # Should discover both .yml and .json files
    node_ids = nodes.map(&:id)
    assert node_ids.include?('test-yaml'), "Should find test-yaml.yml"
    assert node_ids.include?('test-json'), "Should find test-json.json"
  end

  # T019: Test metadata-only nodes (FR-007)
  def test_metadata_only_node
    posts = @root['posts']
    node = posts['metadata-only']

    assert_not_nil node, "Should find metadata-only node"
    assert_equal 'Metadata Only Node', node[:title], "Should load metadata"
  end

  def test_metadata_only_node_has_no_assets
    posts = @root['posts']
    node = posts['metadata-only']

    asset_paths = node.asset_paths

    # Metadata-only node should have no assets (directory doesn't exist)
    assert_equal 0, asset_paths.size, "Metadata-only node should have no assets"
  end

  def test_metadata_only_node_asset_dir_not_required
    posts = @root['posts']
    node = posts['metadata-only']

    # Node should work fine even without asset directory existing
    assert_not_nil node.asset_dir, "asset_dir should still return a path"

    # But the directory doesn't have to exist
    # (This is valid per FR-007: handle metadata-only nodes)
  end

  def test_full_workflow_read
    # Full integration: Root → Collection → Node → Assets
    root = Ro::Root.new(new_structure_path)
    posts = root['posts']
    node = posts['sample-post']

    # Should load everything correctly
    assert_equal 'Sample Post (New Structure)', node[:title]
    assert_equal 'Test Author', node[:author]
    assert node.asset_paths.any?

    # Assets should be accessible
    image_asset = node.asset_paths.find { |p| p.basename.to_s == 'image.jpg' }
    assert_not_nil image_asset, "Should find image.jpg asset"
  end
end

# Run the tests
if __FILE__ == $0
  test = RoIntegrationTest.new

  puts "Running Ro integration tests..."

  tests = [
    :test_load_collection_with_new_structure,
    :test_collection_discovers_nodes_from_metadata_files,
    :test_node_loads_metadata_from_external_file,
    :test_node_loads_assets_from_node_directory,
    :test_nested_assets_preserved,
    :test_multiple_collections,
    :test_multiple_metadata_formats,
    :test_metadata_only_node,
    :test_metadata_only_node_has_no_assets,
    :test_metadata_only_node_asset_dir_not_required,
    :test_full_workflow_read
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
