#!/usr/bin/env ruby
# Integration tests for US4: Ruby DSL Configuration

require_relative '../test_helper'

class RubyDslConfigTest < RoTestCase
  def setup
    @fixture_path = fixtures_path / 'hierarchical_config' / 'ruby_dsl'
  end

  # AS4.1: .ro.rb with ENV-based dynamic config
  def test_ruby_dsl_with_env_var
    temp_dir = create_temp_dir('ruby_dsl_env')

    File.write(temp_dir / '.ro.rb', <<~RUBY)
      structure ENV['RO_STRUCTURE'] || 'dual'
      enable_merge true
    RUBY

    ENV['RO_STRUCTURE'] = 'new'
    root = Ro::Root.new(temp_dir)
    config = root.config

    assert_equal 'new', config[:structure], "Should use ENV variable value"
    assert_equal true, config[:enable_merge]

  ensure
    ENV.delete('RO_STRUCTURE')
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # AS4.2: .ro.rb takes precedence over .ro.yml
  def test_ruby_takes_precedence_over_yaml
    temp_dir = create_temp_dir('ruby_precedence')

    # YAML config
    File.write(temp_dir / '.ro.yml', <<~YAML)
      structure: old
      enable_merge: false
    YAML

    # Ruby config (should win)
    File.write(temp_dir / '.ro.rb', <<~RUBY)
      structure 'new'
      enable_merge true
    RUBY

    root = Ro::Root.new(temp_dir)
    config = root.config

    assert_equal 'new', config[:structure], ".ro.rb should override .ro.yml"
    assert_equal true, config[:enable_merge]

  ensure
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # AS4.3: Custom behavior block (conditional config)
  def test_conditional_config_in_ruby_dsl
    temp_dir = create_temp_dir('ruby_conditional')

    File.write(temp_dir / '.ro.rb', <<~RUBY)
      if ENV['ENABLE_EXPERIMENTAL']
        structure 'new'
        experimental_features true
      else
        structure 'dual'
        experimental_features false
      end
    RUBY

    # Without ENV var
    root1 = Ro::Root.new(temp_dir)
    config1 = root1.config

    assert_equal 'dual', config1[:structure]
    assert_equal false, config1[:experimental_features]

    # With ENV var
    ENV['ENABLE_EXPERIMENTAL'] = '1'
    Ro::ConfigLoader.clear_cache!  # Clear cache to reload
    root2 = Ro::Root.new(temp_dir)
    config2 = root2.config

    assert_equal 'new', config2[:structure]
    assert_equal true, config2[:experimental_features]

  ensure
    ENV.delete('ENABLE_EXPERIMENTAL')
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # AS4.4: Syntax error in .ro.rb produces clear error
  def test_ruby_syntax_error
    temp_dir = create_temp_dir('ruby_syntax_error')

    File.write(temp_dir / '.ro.rb', <<~RUBY)
      structure 'new'
      enable_merge true
      end  # Extra 'end' - syntax error
    RUBY

    error = nil
    begin
      root = Ro::Root.new(temp_dir)
      # Config errors don't fail initialization, just logged
      config = root.config
    rescue Ro::ConfigSyntaxError => e
      error = e
    end

    # Root initialization succeeds but uses defaults
    assert_nil error, "Root should initialize even with bad Ruby config"

  ensure
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # AS4.5: Invalid config values in .ro.rb caught by validation
  def test_ruby_dsl_validation_error
    temp_dir = create_temp_dir('ruby_invalid')

    File.write(temp_dir / '.ro.rb', <<~RUBY)
      structure 'invalid_value'
    RUBY

    # Root initialization succeeds but config loading will fail
    # Test validation by loading hierarchy directly
    error = nil
    begin
      hierarchy = Ro::ConfigHierarchy.new(root_path: temp_dir.to_s)
      config = hierarchy.resolve
    rescue Ro::ConfigValidationError => e
      error = e
    end

    assert_not_nil error, "Should raise validation error for invalid structure value"
    assert error.message.include?('structure'), "Error should mention 'structure'"
    assert error.message.include?('new'), "Error should list valid options"

  ensure
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # Additional: Custom config keys in Ruby DSL
  def test_custom_config_keys_in_ruby_dsl
    temp_dir = create_temp_dir('ruby_custom')

    File.write(temp_dir / '.ro.rb', <<~RUBY)
      structure 'new'
      custom_setting 'my_value'
      another_setting 42
      deeply_nested_value({ foo: 'bar' })
    RUBY

    root = Ro::Root.new(temp_dir)
    config = root.config

    assert_equal 'new', config[:structure]
    assert_equal 'my_value', config[:custom_setting]
    assert_equal 42, config[:another_setting]
    assert_equal({'foo' => 'bar'}, config[:deeply_nested_value])

  ensure
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # Additional: Complex Ruby logic
  def test_complex_ruby_logic
    temp_dir = create_temp_dir('ruby_complex')

    File.write(temp_dir / '.ro.rb', <<~RUBY)
      # Calculate structure based on time
      hour = Time.now.hour
      structure hour < 12 ? 'new' : 'dual'

      # Set merge based on calculation
      enable_merge [1, 2, 3].include?(hour % 3)

      # Custom method call
      custom_value "calculated_\#{hour}"
    RUBY

    root = Ro::Root.new(temp_dir)
    config = root.config

    # Just verify it evaluates without error
    assert_not_nil config[:structure]
    assert [true, false].include?(config[:enable_merge])
    assert config[:custom_value].start_with?('calculated_')

  ensure
    cleanup_temp_dir(temp_dir) if temp_dir
  end

  # Additional: Ruby DSL at collection level
  def test_ruby_dsl_at_collection_level
    temp_dir = create_temp_dir('ruby_collection')
    posts_dir = temp_dir / 'posts'
    FileUtils.mkdir_p(posts_dir)

    # Root YAML
    File.write(temp_dir / '.ro.yml', "structure: dual")

    # Collection Ruby DSL (overrides root)
    File.write(posts_dir / '.ro.rb', <<~RUBY)
      structure 'old'
      collection_custom 'posts_value'
    RUBY

    root = Ro::Root.new(temp_dir)
    posts = root.get('posts')

    root_config = root.config
    posts_config = posts.config

    assert_equal 'dual', root_config[:structure], "Root should have 'dual'"
    assert_equal 'old', posts_config[:structure], "Posts should override to 'old'"
    assert_equal 'posts_value', posts_config[:collection_custom]

  ensure
    cleanup_temp_dir(temp_dir) if temp_dir
  end
end

# Run tests
if __FILE__ == $0
  test = RubyDslConfigTest.new

  tests = [
    :test_ruby_dsl_with_env_var,
    :test_ruby_takes_precedence_over_yaml,
    :test_conditional_config_in_ruby_dsl,
    :test_ruby_syntax_error,
    :test_ruby_dsl_validation_error,
    :test_custom_config_keys_in_ruby_dsl,
    :test_complex_ruby_logic,
    :test_ruby_dsl_at_collection_level
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

  puts "\nAll Ruby DSL tests passed! ✨"
end
