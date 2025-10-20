require_relative '../test_helper'

class DualStructureTest < RoTestCase
  def setup
    @test_dir = Pathname.new(Dir.mktmpdir("dual_structure_test"))
    @ro_dir = @test_dir.join('ro')
    @posts_dir = @ro_dir.join('posts')
    @posts_dir.mkpath
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if @test_dir && @test_dir.exist?
  end

  def test_discovers_new_structure_nodes
    # Create new structure: posts/foo.yml
    File.write(@posts_dir.join('foo.yml'), {title: 'Foo New'}.to_yaml)
    @posts_dir.join('foo').mkpath

    root = Ro::Root.new(@ro_dir)
    posts = root.posts

    assert_equal 1, posts.to_a.size
    assert_equal 'foo', posts.first.id
    assert_equal 'Foo New', posts.first.attributes[:title]
  end

  def test_discovers_old_structure_nodes
    # Create old structure: posts/bar/attributes.yml
    bar_dir = @posts_dir.join('bar')
    bar_dir.mkpath
    File.write(bar_dir.join('attributes.yml'), {title: 'Bar Old'}.to_yaml)

    root = Ro::Root.new(@ro_dir)
    posts = root.posts

    assert_equal 1, posts.to_a.size
    assert_equal 'bar', posts.first.id
    assert_equal 'Bar Old', posts.first.attributes[:title]
  end

  def test_discovers_both_structure_types_simultaneously
    # Create new structure node
    File.write(@posts_dir.join('new-node.yml'), {title: 'New Structure'}.to_yaml)
    @posts_dir.join('new-node').mkpath

    # Create old structure node
    old_dir = @posts_dir.join('old-node')
    old_dir.mkpath
    File.write(old_dir.join('attributes.yml'), {title: 'Old Structure'}.to_yaml)

    root = Ro::Root.new(@ro_dir)
    posts = root.posts
    nodes = posts.to_a

    assert_equal 2, nodes.size

    new_node = nodes.find { |n| n.id == 'new-node' }
    old_node = nodes.find { |n| n.id == 'old-node' }

    assert_equal 'New Structure', new_node.attributes[:title]
    assert_equal 'Old Structure', old_node.attributes[:title]
  end

  def test_new_structure_takes_precedence_over_old
    # Create both structures for same node - new should win
    node_id = 'conflict'

    # New structure
    File.write(@posts_dir.join("#{node_id}.yml"), {title: 'New Wins'}.to_yaml)

    # Old structure
    node_dir = @posts_dir.join(node_id)
    node_dir.mkpath
    File.write(node_dir.join('attributes.yml'), {title: 'Old Loses'}.to_yaml)

    root = Ro::Root.new(@ro_dir)
    posts = root.posts
    node = posts.to_a.first

    assert_equal 'conflict', node.id
    assert_equal 'New Wins', node.attributes[:title]
  end

  def test_mixed_structure_with_assets
    # New structure with assets
    File.write(@posts_dir.join('new-with-assets.yml'), {title: 'New'}.to_yaml)
    new_assets_dir = @posts_dir.join('new-with-assets', 'assets')
    new_assets_dir.mkpath
    File.write(new_assets_dir.join('image.jpg'), 'fake jpg')

    # Old structure with assets
    old_dir = @posts_dir.join('old-with-assets')
    old_dir.mkpath
    File.write(old_dir.join('attributes.yml'), {title: 'Old'}.to_yaml)
    old_assets_dir = old_dir.join('assets')
    old_assets_dir.mkpath
    File.write(old_assets_dir.join('photo.png'), 'fake png')

    root = Ro::Root.new(@ro_dir)
    posts = root.posts
    nodes = posts.to_a

    assert_equal 2, nodes.size

    new_node = nodes.find { |n| n.id == 'new-with-assets' }
    old_node = nodes.find { |n| n.id == 'old-with-assets' }

    # Both should have assets
    assert_equal 1, new_node.assets.size
    assert new_node.assets.first.to_s.include?('image.jpg')

    assert_equal 1, old_node.assets.size
    assert old_node.assets.first.to_s.include?('photo.png')
  end

  def test_iteration_order_consistent
    # Create nodes with both structures
    File.write(@posts_dir.join('a-new.yml'), {}.to_yaml)
    @posts_dir.join('a-new').mkpath

    b_dir = @posts_dir.join('b-old')
    b_dir.mkpath
    File.write(b_dir.join('attributes.yml'), {}.to_yaml)

    File.write(@posts_dir.join('c-new.yml'), {}.to_yaml)
    @posts_dir.join('c-new').mkpath

    root = Ro::Root.new(@ro_dir)
    posts = root.posts
    ids = posts.to_a.map(&:id)

    # Should be sorted alphabetically regardless of structure type
    assert_equal ['a-new', 'b-old', 'c-new'], ids
  end

  def test_supports_multiple_metadata_formats
    # New structure with different formats
    File.write(@posts_dir.join('yaml-new.yml'), {format: 'yaml'}.to_yaml)
    @posts_dir.join('yaml-new').mkpath

    File.write(@posts_dir.join('json-new.json'), {format: 'json'}.to_json)
    @posts_dir.join('json-new').mkpath

    # Old structure with different formats
    yaml_old_dir = @posts_dir.join('yaml-old')
    yaml_old_dir.mkpath
    File.write(yaml_old_dir.join('attributes.yaml'), {format: 'yaml_old'}.to_yaml)

    json_old_dir = @posts_dir.join('json-old')
    json_old_dir.mkpath
    File.write(json_old_dir.join('attributes.json'), {format: 'json_old'}.to_json)

    root = Ro::Root.new(@ro_dir)
    posts = root.posts
    nodes = posts.to_a

    assert_equal 4, nodes.size

    formats = nodes.map { |n| n.attributes[:format] }.sort
    assert_equal ['json', 'json_old', 'yaml', 'yaml_old'], formats
  end
end
