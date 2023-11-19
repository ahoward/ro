module Ro
  class Root < Path
    attr_reader :url

    class << Root
      def for(arg, *args, **kws, &block)
        return arg if arg.is_a?(Root) && args.empty? && kws.empty? && block.nil?

        new(arg, *args, **kws, &block)
      end

      def collections_for(root)
        root = Root.for(root)

        Collection.new(root) do |nodes_path|
          Collection.new(nodes_path) do |node_path|
            Node.new(node_path, root: root)
          end
        end
      end
    end

    def self.default
      Root.for(default_path)
    end

    def self.default_path
      Ro.config.root || Ro.config.path.detect { |path| Path.for(path).exist? }
    end

    def self.default_url
      Ro.config.url
    end

    def initialize(path = Root.default_path, options = {})
      super(path)

      @url = Ro.normalize_url(options.fetch(:url) { Root.default_url })
    ensure
      Ro.error!("root=#{inspect} is not as a directory") unless exist? && directory?
    end

    def collections
      @collections ||= Root.collections_for(self)
    end

    def nodes(&block)
      [].tap do |accum|
        glob('*/*/attributes.yml') do |entry|
          path = entry.dirname
          node = Node.new(path, root: self)
          accum.push(block ? block.call(node) : node)
        end
      end
    end
  end
end
