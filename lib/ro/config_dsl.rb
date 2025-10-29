module Ro
  # ConfigDSL provides a Ruby DSL for .ro.rb configuration files
  #
  # Uses instance_eval pattern (like Bundler's Gemfile) for clean syntax.
  # Configuration values are set via method calls.
  #
  # @example .ro.rb file
  #   # Simple values
  #   structure 'new'
  #   enable_merge true
  #
  #   # Conditional logic
  #   if ENV['PRODUCTION']
  #     structure 'new'
  #   else
  #     structure 'dual'
  #   end
  #
  #   # Custom settings
  #   custom_setting 'my_value'
  #
  class ConfigDSL
    attr_reader :config

    def initialize
      @config = {}
    end

    # Evaluate a .ro.rb file
    #
    # @param file_path [String, Pathname] Path to .ro.rb file
    # @return [Map] Configuration hash
    # @raise [ConfigEvaluationError] If evaluation fails
    #
    def self.evaluate(file_path)
      dsl = new
      content = File.read(file_path)

      begin
        dsl.instance_eval(content, file_path.to_s, 1)
      rescue SyntaxError => e
        raise ConfigSyntaxError.new(
          "Ruby syntax error in config file",
          file_path: file_path.to_s,
          line_number: extract_line_number(e),
          original_error: e,
          suggestion: "Check Ruby syntax: #{e.message}"
        )
      rescue => e
        raise ConfigEvaluationError.new(
          "Error evaluating Ruby config file",
          file_path: file_path.to_s,
          line_number: extract_line_number(e),
          original_error: e,
          suggestion: "Check Ruby code in #{file_path}"
        )
      end

      Map.for(dsl.config)
    end

    # DSL method: Set structure preference
    #
    def structure(value)
      @config['structure'] = value.to_s
    end

    # DSL method: Set enable_merge flag
    #
    def enable_merge(value)
      @config['enable_merge'] = !!value
    end

    # DSL method: Set merge_attributes flag (node level)
    #
    def merge_attributes(value)
      @config['merge_attributes'] = !!value
    end

    # Handle unknown methods as custom config keys
    #
    # This allows arbitrary config keys like:
    #   custom_setting 'value'
    #
    def method_missing(name, *args, &block)
      if args.length == 1 && !block
        # Setting a value: method_name(value)
        @config[name.to_s] = args.first
      elsif args.empty? && !block
        # Getting a value: method_name
        @config[name.to_s]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      true
    end

    private

    # Extract line number from exception
    #
    def self.extract_line_number(error)
      if error.respond_to?(:line)
        error.line
      elsif error.backtrace && error.backtrace.first
        # Extract from backtrace: "file.rb:123:in `method'"
        match = error.backtrace.first.match(/:(\d+):/)
        match ? match[1].to_i : nil
      else
        nil
      end
    end
  end
end
