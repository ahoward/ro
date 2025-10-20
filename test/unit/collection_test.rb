#!/usr/bin/env ruby
# Unit tests for Ro::Collection with new structure support

require_relative '../test_helper'

class CollectionTest < RoTestCase
  def setup
    @root = Ro::Root.new(new_structure_path)
    @collection = Ro::Collection.new(new_structure_path / 'posts')
  end

  # T011: Test Collection#metadata_files
  def test_metadata_files_returns_yml_and_json_files
    entries = @collection.metadata_files

    assert_not_nil entries, "metadata_files should not be nil"
    assert entries.is_a?(Array), "metadata_files should return an Array"

    # Should find .yml and .json files
    yml_entries = entries.select { |e| e[:path].to_s.end_with?('.yml') }
    assert yml_entries.any?, "Should find at least one .yml file"

    # Each entry should be a hash with :id, :path, :type
    assert entries.all? { |e| e.is_a?(Hash) && e[:id] && e[:path] && e[:type] }, "All entries should be hashes with :id, :path, :type"
  end

  def test_metadata_files_excludes_directories
    entries = @collection.metadata_files

    # Should only return files, not directories
    assert entries.all? { |e| e[:path].file? }, "metadata_files should only return file entries"
  end

  def test_metadata_files_sorted
    entries = @collection.metadata_files

    # Should be sorted by id
    ids = entries.map { |e| e[:id] }
    assert_equal ids.sort, ids, "metadata_files should be sorted by id"
  end

  # T012: Test Collection#each with new structure
  def test_each_iterates_nodes_from_metadata_files
    nodes = []
    @collection.each do |node|
      nodes << node
    end

    assert nodes.any?, "Collection should have at least one node"
    assert nodes.all? { |n| n.is_a?(Ro::Node) }, "All items should be Node instances"
  end

  def test_each_creates_nodes_from_metadata_files
    node_ids = []
    @collection.each do |node|
      node_ids << node.id
    end

    # Should find nodes based on metadata files
    assert node_ids.include?('sample-post'), "Should find sample-post node"
    assert node_ids.include?('metadata-only'), "Should find metadata-only node"
    assert node_ids.include?('nested-test'), "Should find nested-test node"
  end

  def test_each_without_block_returns_enumerator
    enum = @collection.each

    assert enum.is_a?(Enumerator), "each without block should return Enumerator"

    nodes = enum.to_a
    assert nodes.any?, "Enumerator should yield nodes"
  end
end

# Run the tests
if __FILE__ == $0
  test = CollectionTest.new

  puts "Running Collection unit tests..."

  begin
    test.setup
    test.test_metadata_files_returns_yml_and_json_files
    puts "✓ test_metadata_files_returns_yml_and_json_files"
  rescue => e
    puts "✗ test_metadata_files_returns_yml_and_json_files: #{e.message}"
  end

  begin
    test.setup
    test.test_metadata_files_excludes_directories
    puts "✓ test_metadata_files_excludes_directories"
  rescue => e
    puts "✗ test_metadata_files_excludes_directories: #{e.message}"
  end

  begin
    test.setup
    test.test_metadata_files_sorted
    puts "✓ test_metadata_files_sorted"
  rescue => e
    puts "✗ test_metadata_files_sorted: #{e.message}"
  end

  begin
    test.setup
    test.test_each_iterates_nodes_from_metadata_files
    puts "✓ test_each_iterates_nodes_from_metadata_files"
  rescue => e
    puts "✗ test_each_iterates_nodes_from_metadata_files: #{e.message}"
  end

  begin
    test.setup
    test.test_each_creates_nodes_from_metadata_files
    puts "✓ test_each_creates_nodes_from_metadata_files"
  rescue => e
    puts "✗ test_each_creates_nodes_from_metadata_files: #{e.message}"
  end

  begin
    test.setup
    test.test_each_without_block_returns_enumerator
    puts "✓ test_each_without_block_returns_enumerator"
  rescue => e
    puts "✗ test_each_without_block_returns_enumerator: #{e.message}"
  end
end
