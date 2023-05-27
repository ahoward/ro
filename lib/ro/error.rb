module Ro
  class Error < ::StandardError
    def initialize(message, context = nil)
      super(message)
      @context = context
    end
  end
end
