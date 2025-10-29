#!/usr/bin/env ruby
# Integration tests for US2: Collection-Level Configuration Override

require_relative '../test_helper'

class CollectionConfigTest < RoTestCase
  def setup
    @fixture_path = fixtures_path / 'hierarchical_config' / 'collection_override'
    @root = Ro::Root.new(@fixture_path)
    @posts_collection = @root.get('posts')
  end

  # AS2.1: Root has structure:new, posts has structure:old
  def test_collection_overrides_root_structure
    root_config = @root.config
    posts_config = @posts_collection.config

    assert_equal 'new', root_config[:structure], "Root should have structure:new"
    assert_equal 'old', posts_config[:structure], "Posts collection should override to structure:old"
  end

  # AS2.2: Collection-level config takes precedence (deeper wins)
  def test_deeper_wins_precedence
    posts_config = @posts_collection.config

    # structure overridden at collection level
    assert_equal 'old', posts_config[:structure]

    # enable_merge inherited from root
    assert_equal true, posts_config[:enable_merge]
  end

  # AS2.3: Collection with config, root without config
  def test_collection_config_without_root_config
    # Create temp structure with only collection config
    temp_dir = create_temp_dir('coll_only')
    coll_dir = temp_dir / 'posts'
    FileUtils.mkdir_p(coll_dir)

    File.write(coll_dir / '.ro.yml', "structure: old\ncustom: collection_value")

    root = Ro::Root.new(temp_dir)
    collection = root.get('posts')

    config = collection.config

    # Collection config applies
    assert_equal 'old', config[:structure]
    assert_equal 'collection_value', config[:custom]

    # Root defaults also present
    assert_equal true, config[:enable_merge]

  ensure
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # AS2.4: Invalid structure value at collection level
  def test_invalid_structure_value_error
    temp_dir = create_temp_dir('invalid_struct')
    coll_dir = temp_dir / 'posts'
    FileUtils.mkdir_p(coll_dir)

    File.write(coll_dir / '.ro.yml', "structure: invalid_value")

    root = Ro::Root.new(temp_dir)
    collection = root.get('posts')

    error = nil
    begin
      config = collection.config
    rescue Ro::ConfigValidationError => e
      error = e
    end

    assert_not_nil error, "Should raise ConfigValidationError for invalid structure value"
    assert error.message.include?('structure'), "Error should mention the 'structure' key"
    assert error.message.include?('new'), "Error should list valid options"

  ensure
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # Additional: Multiple collections with different configs
  def test_multiple_collections_independent_configs
    # Create temp structure with two collections
    temp_dir = create_temp_dir('multi_coll')

    posts_dir = temp_dir / 'posts'
    pages_dir = temp_dir / 'pages'
    FileUtils.mkdir_p(posts_dir)
    FileUtils.mkdir_p(pages_dir)

    File.write(posts_dir / '.ro.yml', "structure: old")
    File.write(pages_dir / '.ro.yml', "structure: new")

    root = Ro::Root.new(temp_dir)
    posts = root.get('posts')
    pages = root.get('pages')

    assert_equal 'old', posts.config[:structure]
    assert_equal 'new', pages.config[:structure]

  ensure
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # Additional: Collection config is cached
  def test_collection_config_caching
    config1 = @posts_collection.config
    config2 = @posts_collection.config

    assert config1.object_id == config2.object_id, "Collection config should be cached"
  end

  # Additional: Config introspection shows source
  def test_config_sources_introspection
    hierarchy = Ro::ConfigHierarchy.new(
      root_path: @fixture_path.to_s,
      collection_path: (@fixture_path / 'posts').to_s
    )

    sources = hierarchy.sources

    assert_equal :collection, sources['structure'], "structure comes from collection level"
    assert_equal :root, sources['enable_merge'], "enable_merge comes from root level"
  end
end

# Run tests
if __FILE__ == $0
  test = CollectionConfigTest.new

  tests = [
    :test_collection_overrides_root_structure,
    :test_deeper_wins_precedence,
    :test_collection_config_without_root_config,
    :test_invalid_structure_value_error,
    :test_multiple_collections_independent_configs,
    :test_collection_config_caching,
    :test_config_sources_introspection
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

  puts "\nAll collection config tests passed! ✨"
end
