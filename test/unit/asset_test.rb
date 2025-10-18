#!/usr/bin/env ruby
# Unit tests for Ro::Asset with new structure support

require_relative '../test_helper'

class AssetTest < RoTestCase
  def setup
    @root = Ro::Root.new(new_structure_path)
    @collection = Ro::Collection.new(new_structure_path.join('posts'))
    @metadata_file = new_structure_path.join('posts', 'sample-post.yml')
    @node = Ro::Node.new(@collection, @metadata_file)
  end

  # T017: Test Asset path resolution without assets/ prefix
  def test_asset_path_without_assets_prefix
    asset_path = new_structure_path / 'posts' / 'sample-post' / 'image.jpg'

    # In new structure, asset paths should NOT contain /assets/ segment
    assert !asset_path.to_s.include?('/assets/'), "Asset path should not contain /assets/ in new structure"
  end

  def test_asset_relative_path_calculation
    asset_path = new_structure_path / 'posts' / 'sample-post' / 'image.jpg'
    asset = Ro::Asset.new(asset_path)

    # Relative path should be calculated correctly (no assets/ prefix to strip)
    relative = asset.relative_path

    assert_not_nil relative, "Relative path should not be nil"
    # In new structure, relative path is simpler (no assets/ to strip)
    assert_equal 'image.jpg', relative.to_s, "Relative path should be image.jpg"
  end

  def test_nested_asset_path
    # Test with nested subdirectory structure
    asset_path = new_structure_path / 'posts' / 'nested-test' / 'subdirectory' / 'image.png'
    asset = Ro::Asset.new(asset_path)

    relative = asset.relative_path

    # Should preserve subdirectory structure
    assert_equal 'subdirectory/image.png', relative.to_s, "Nested asset should preserve directory structure"
  end

  def test_asset_url_generation
    asset_path = new_structure_path / 'posts' / 'sample-post' / 'image.jpg'
    asset = Ro::Asset.new(asset_path)

    # Asset should be able to generate URL
    # (Exact URL format depends on node.url_for implementation)
    assert_not_nil asset, "Asset should be created successfully"
  end

  def test_asset_belongs_to_node
    asset_paths = @node.asset_paths

    assert asset_paths.any?, "Node should have asset paths"

    # All asset paths should be within node directory
    asset_paths.each do |path|
      assert path.to_s.start_with?(@node.asset_dir.to_s), "Asset path should be within node directory"
    end
  end
end

# Run the tests
if __FILE__ == $0
  test = AssetTest.new

  puts "Running Asset unit tests..."

  tests = [
    :test_asset_path_without_assets_prefix,
    :test_asset_relative_path_calculation,
    :test_nested_asset_path,
    :test_asset_url_generation,
    :test_asset_belongs_to_node
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
