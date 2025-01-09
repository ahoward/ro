# frozen_string_literal: true

unless defined?(ActiveSupport::SafeBuffer)

class Object
  def html_safe?
    false
  end
end

class Numeric
  def html_safe?
    true
  end
end

module ActiveSupport #:nodoc:
  class SafeBuffer < String
    UNSAFE_STRING_METHODS = %w(
      capitalize chomp chop delete downcase gsub lstrip next reverse rstrip
      slice squeeze strip sub succ swapcase tr tr_s upcase
    )

    alias_method :original_concat, :concat
    private :original_concat

    # Raised when <tt>ActiveSupport::SafeBuffer#safe_concat</tt> is called on unsafe buffers.
    class SafeConcatError < StandardError
      def initialize
        super "Could not concatenate to the buffer because it is not html safe."
      end
    end

    def [](*args)
      if args.size < 2
        super
      elsif html_safe?
        new_safe_buffer = super

        if new_safe_buffer
          new_safe_buffer.instance_variable_set :@html_safe, true
        end

        new_safe_buffer
      else
        to_str[*args]
      end
    end

    def safe_concat(value)
      raise SafeConcatError unless html_safe?
      original_concat(value)
    end

    def initialize(str = "")
      @html_safe = true
      super
    end

    def initialize_copy(other)
      super
      @html_safe = other.html_safe?
    end

    def clone_empty
      self[0, 0]
    end

    def concat(value)
      super(html_escape_interpolated_argument(value))
    end
    alias << concat

    def prepend(value)
      super(html_escape_interpolated_argument(value))
    end

    def +(other)
      dup.concat(other)
    end

    def %(args)
      case args
      when Hash
        escaped_args = Hash[args.map { |k, arg| [k, html_escape_interpolated_argument(arg)] }]
      else
        escaped_args = Array(args).map { |arg| html_escape_interpolated_argument(arg) }
      end

      self.class.new(super(escaped_args))
    end

    def html_safe?
      defined?(@html_safe) && @html_safe
    end

    def to_s
      self
    end

    def to_param
      to_str
    end

    def encode_with(coder)
      coder.represent_object nil, to_str
    end

    UNSAFE_STRING_METHODS.each do |unsafe_method|
      if unsafe_method.respond_to?(unsafe_method)
        class_eval <<-EOT, __FILE__, __LINE__ + 1
          def #{unsafe_method}(*args, &block)       # def capitalize(*args, &block)
            to_str.#{unsafe_method}(*args, &block)  #   to_str.capitalize(*args, &block)
          end                                       # end

          def #{unsafe_method}!(*args)              # def capitalize!(*args)
            @html_safe = false                      #   @html_safe = false
            super                                   #   super
          end                                       # end
        EOT
      end
    end

    private

      def html_escape_interpolated_argument(arg)
        (!html_safe? || arg.html_safe?) ? arg : CGI.escapeHTML(arg.to_s)
      end
  end
end

class String
  # Marks a string as trusted safe. It will be inserted into HTML with no
  # additional escaping performed. It is your responsibility to ensure that the
  # string contains no malicious content. This method is equivalent to the
  # +raw+ helper in views. It is recommended that you use +sanitize+ instead of
  # this method. It should never be called on user input.
  def html_safe
    ActiveSupport::SafeBuffer.new(self)
  end
end

end
