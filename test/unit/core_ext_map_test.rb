require_relative '../test_helper'

class CoreExtMapTest < RoTestCase
  def test_deep_merge_with_scalar_override
    base = Map.for(a: 1, b: 2)
    override = Map.for(b: 3, c: 4)

    result = base.deep_merge(override)

    assert_equal 1, result[:a]
    assert_equal 3, result[:b] # override wins
    assert_equal 4, result[:c]
  end

  def test_deep_merge_with_nested_hashes
    base = Map.for(
      structure: 'new',
      settings: {
        merge: true,
        cache: false
      }
    )

    override = Map.for(
      structure: 'old',
      settings: {
        cache: true
      }
    )

    result = base.deep_merge(override)

    assert_equal 'old', result[:structure]
    assert_equal true, result[:settings][:merge] # preserved from base
    assert_equal true, result[:settings][:cache] # override wins
  end

  def test_deep_merge_preserves_base_when_no_conflict
    base = Map.for(a: 1, b: 2, c: 3)
    override = Map.for(d: 4)

    result = base.deep_merge(override)

    assert_equal 1, result[:a]
    assert_equal 2, result[:b]
    assert_equal 3, result[:c]
    assert_equal 4, result[:d]
  end

  def test_deep_merge_with_nil_value
    base = Map.for(a: 1, b: 2)
    override = Map.for(b: nil)

    result = base.deep_merge(override)

    assert_equal 1, result[:a]
    assert_nil result[:b] # nil explicitly overrides
  end

  def test_deep_merge_with_type_mismatch
    base = Map.for(setting: {nested: 'value'})
    override = Map.for(setting: 'scalar')

    result = base.deep_merge(override)

    assert_equal 'scalar', result[:setting] # scalar replaces hash
  end

  def test_deep_merge_with_array_replacement
    base = Map.for(tags: ['a', 'b'])
    override = Map.for(tags: ['c', 'd'])

    result = base.deep_merge(override)

    assert_equal ['c', 'd'], result[:tags] # arrays replaced, not merged
  end

  def test_deep_merge_three_levels
    root = Map.for(
      structure: 'dual',
      merge: true,
      root_only: 'value'
    )

    collection = Map.for(
      structure: 'new',
      collection_only: 'value'
    )

    node = Map.for(
      structure: 'old',
      node_only: 'value'
    )

    result = root.deep_merge(collection).deep_merge(node)

    assert_equal 'old', result[:structure] # node wins
    assert_equal true, result[:merge] # from root
    assert_equal 'value', result[:root_only]
    assert_equal 'value', result[:collection_only]
    assert_equal 'value', result[:node_only]
  end

  def test_deep_merge_does_not_modify_original
    base = Map.for(a: 1, b: 2)
    override = Map.for(b: 3)

    result = base.deep_merge(override)

    assert_equal 2, base[:b] # original unchanged
    assert_equal 3, result[:b]
  end

  def test_deep_merge_with_plain_hash
    base = Map.for(a: 1)
    override = {b: 2}

    result = base.deep_merge(override)

    assert_equal 1, result[:a]
    assert_equal 2, result[:b]
    assert result.is_a?(Map), "Expected result to be a Map"
  end

  def test_deep_merge_deeply_nested_structures
    base = Map.for(
      level1: {
        level2: {
          level3: {
            value: 'base'
          }
        }
      }
    )

    override = Map.for(
      level1: {
        level2: {
          level3: {
            value: 'override',
            new_key: 'new'
          }
        }
      }
    )

    result = base.deep_merge(override)

    assert_equal 'override', result[:level1][:level2][:level3][:value]
    assert_equal 'new', result[:level1][:level2][:level3][:new_key]
  end
end

# Run tests
if __FILE__ == $0
  test = CoreExtMapTest.new

  tests = [
    :test_deep_merge_with_scalar_override,
    :test_deep_merge_with_nested_hashes,
    :test_deep_merge_preserves_base_when_no_conflict,
    :test_deep_merge_with_nil_value,
    :test_deep_merge_with_type_mismatch,
    :test_deep_merge_with_array_replacement,
    :test_deep_merge_three_levels,
    :test_deep_merge_does_not_modify_original,
    :test_deep_merge_with_plain_hash,
    :test_deep_merge_deeply_nested_structures
  ]

  tests.each do |test_method|
    begin
      test.setup if test.respond_to?(:setup)
      test.send(test_method)
      puts "✓ #{test_method}"
    rescue => e
      puts "✗ #{test_method}: #{e.message}"
      puts "  #{e.backtrace.first}"
      exit 1
    end
  end
end
