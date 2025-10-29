module Ro
  class Error < ::StandardError
    attr_reader :context

    def initialize(message, **context)
      @context = context
      msg = context.empty? ? "#{ message }" : "#{ message }, #{ context.inspect }"
      super(msg)
    end
  end

  # Config-specific errors
  class ConfigError < Error
    attr_reader :file_path, :line_number, :original_error, :suggestion

    def initialize(message, file_path: nil, line_number: nil, original_error: nil, suggestion: nil, **context)
      @file_path = file_path
      @line_number = line_number
      @original_error = original_error
      @suggestion = suggestion

      # Build formatted message
      parts = [message]
      parts << "Location: #{file_path}:#{line_number}" if file_path && line_number
      parts << "Location: #{file_path}" if file_path && !line_number
      parts << "Suggestion: #{suggestion}" if suggestion

      full_message = parts.join("\n")
      super(full_message, **context)
    end
  end

  class ConfigSyntaxError < ConfigError
  end

  class ConfigEvaluationError < ConfigError
  end

  class ConfigValidationError < ConfigError
  end

  class ConfigFileNotFoundError < ConfigError
  end

  class ConfigPermissionError < ConfigError
  end
end
