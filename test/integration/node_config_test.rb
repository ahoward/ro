#!/usr/bin/env ruby
# Integration tests for US3: Node-Level Configuration Override

require_relative '../test_helper'

class NodeConfigTest < RoTestCase
  def setup
    @fixture_path = fixtures_path / 'hierarchical_config' / 'node_override'

    # Create minimal node structure for testing
    posts_dir = @fixture_path / 'posts'
    special_post_dir = posts_dir / 'special-post'

    # Ensure structure exists
    FileUtils.mkdir_p(special_post_dir) unless special_post_dir.exist?

    # Create metadata file if it doesn't exist
    metadata_file = posts_dir / 'special-post.yml'
    unless metadata_file.exist?
      File.write(metadata_file, {title: 'Special Post', content: 'Test'}.to_yaml)
    end

    @root = Ro::Root.new(@fixture_path)
    @posts = @root.get('posts')
    @special_post = @posts.nodes.first if @posts && @posts.nodes.any?
  end

  # AS3.1: Node directory with .ro.yml overrides collection and root
  def test_node_overrides_collection_and_root
    skip "No node found" unless @special_post

    node_config = @special_post.config

    # Node-specific setting
    assert_equal false, node_config[:merge_attributes], "Node should override merge_attributes to false"

    # Inherited from collection
    assert_equal 'new', node_config[:structure], "Should inherit structure from collection"

    # Inherited from root
    assert_equal true, node_config[:enable_merge], "Should inherit enable_merge from root"
  end

  # AS3.2: merge_attributes setting at node level
  def test_merge_attributes_node_setting
    skip "No node found" unless @special_post

    config = @special_post.config

    assert_equal false, config[:merge_attributes], "merge_attributes should be false from node config"
  end

  # AS3.3: Custom settings at node level
  def test_custom_node_settings
    skip "No node found" unless @special_post

    config = @special_post.config

    assert_equal 'node_value', config[:custom_node_setting], "Custom node setting should be accessible"
  end

  # AS3.4: Query effective config with precedence chain
  def test_effective_config_shows_all_levels
    skip "No node found" unless @special_post

    hierarchy = Ro::ConfigHierarchy.new(
      root_path: @fixture_path.to_s,
      collection_path: (@fixture_path / 'posts').to_s,
      node_path: (@fixture_path / 'posts' / 'special-post').to_s
    )

    effective = hierarchy.resolve
    sources = hierarchy.sources

    # Verify precedence
    assert_equal :root, sources['enable_merge'], "enable_merge from root"
    assert_equal :collection, sources['structure'], "structure from collection"
    assert_equal :node, sources['merge_attributes'], "merge_attributes from node"
    assert_equal :node, sources['custom_node_setting'], "custom_node_setting from node"
  end

  # Additional: Node without config inherits from collection
  def test_node_without_config_inherits
    temp_dir = create_temp_dir('node_inherit')
    posts_dir = temp_dir / 'posts'
    node_dir = posts_dir / 'regular-post'
    FileUtils.mkdir_p(node_dir)

    # Root config
    File.write(temp_dir / '.ro.yml', "structure: dual")

    # Collection config
    File.write(posts_dir / '.ro.yml', "structure: new\nenable_merge: false")

    # Node metadata (no node config)
    File.write(posts_dir / 'regular-post.yml', {title: 'Regular'}.to_yaml)

    root = Ro::Root.new(temp_dir)
    posts = root.get('posts')
    node = posts.nodes.first

    config = node.config

    # Should inherit from collection
    assert_equal 'new', config[:structure]
    assert_equal false, config[:enable_merge]

  ensure
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # Additional: Three-level precedence verification
  def test_three_level_precedence
    temp_dir = create_temp_dir('three_level')
    posts_dir = temp_dir / 'posts'
    node_dir = posts_dir / 'test-post'
    FileUtils.mkdir_p(node_dir)

    # Root: structure=dual, merge=true, custom=root
    File.write(temp_dir / '.ro.yml', <<~YAML)
      structure: dual
      enable_merge: true
      custom_setting: root_value
    YAML

    # Collection: structure=new, other=collection
    File.write(posts_dir / '.ro.yml', <<~YAML)
      structure: new
      other_setting: collection_value
    YAML

    # Node: structure=old, node_only=node
    File.write(node_dir / '.ro.yml', <<~YAML)
      structure: old
      node_only_setting: node_value
    YAML

    # Node metadata
    File.write(posts_dir / 'test-post.yml', {title: 'Test'}.to_yaml)

    root = Ro::Root.new(temp_dir)
    node = root.get('posts').nodes.first

    config = node.config

    # Node wins
    assert_equal 'old', config[:structure]
    assert_equal 'node_value', config[:node_only_setting]

    # Collection wins (not overridden by node)
    assert_equal 'collection_value', config[:other_setting]

    # Root wins (not overridden)
    assert_equal true, config[:enable_merge]
    assert_equal 'root_value', config[:custom_setting]

  ensure
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # Additional: Node config is cached
  def test_node_config_caching
    skip "No node found" unless @special_post

    config1 = @special_post.config
    config2 = @special_post.config

    assert config1.object_id == config2.object_id, "Node config should be cached"
  end
end

# Run tests
if __FILE__ == $0
  test = NodeConfigTest.new

  tests = [
    :test_node_overrides_collection_and_root,
    :test_merge_attributes_node_setting,
    :test_custom_node_settings,
    :test_effective_config_shows_all_levels,
    :test_node_without_config_inherits,
    :test_three_level_precedence,
    :test_node_config_caching
  ]

  tests.each do |test_method|
    begin
      test.setup
      test.send(test_method)
      puts "✓ #{test_method}"
    rescue RoTestCase::SkipError => e
      puts "⊘ #{test_method}: #{e.message}"
    rescue => e
      puts "✗ #{test_method}: #{e.message}"
      puts "  #{e.backtrace.first(3).join("\n  ")}"
      exit 1
    ensure
      test.teardown if test.respond_to?(:teardown)
    end
  end

  puts "\nAll node config tests passed! ✨"
end
