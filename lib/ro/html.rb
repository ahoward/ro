module Ro
  require_relative 'html_safe'

  class HTML < ::ActiveSupport::SafeBuffer
    def initialize(*args, **kws, &block)
      self.front_matter = kws.fetch(:front_matter){ {} }

      super(args.join)
    end

    def front_matter
      @front_matter ||= Map.new
    end

    def front_matter=(hash = {})
      @front_matter = Map.for(hash)
    end

    def attributes
      front_matter
    end
  end
end
