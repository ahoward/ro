module Ro
  class Asset < ::String
    class << Asset
      def for(arg, *args, **kws, &block)
        return arg if arg.is_a?(Path) && args.empty? && kws.empty? && block.nil?

        new(arg, *args, **kws, &block)
      end
    end

    attr_reader :path, :node, :relative_path, :name, :url

    def initialize(arg, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}

      @path = Path.for(arg, *args)

      @node = options.fetch(:node) { Node.for(@path.split('/assets/').first) }

      @relative_path = @path.relative_to(@node.path)

      @name = @relative_path

      @url = @node.url_for(@relative_path)

      super(@path)
    end

    def image?
      @path.image?
    end

    def src
      key = relative_path.parts
      subdir = key.size > 2 ? key[1] : nil
      is_src = subdir == 'src'

      return unless is_src

      Ro.render_src(path, node)
    end
  end
end
