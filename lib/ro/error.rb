module Ro
  class Error < ::StandardError
    attr_reader :context

    def initialize(message, **context)
      @context = context

      msg = context.empty? ? "#{ message }" : "#{ message }, #{ context.inspect }"

      super(msg)
    end
  end
end
