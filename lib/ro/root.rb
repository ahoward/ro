module Ro
  class Root < ::String
    attr_reader :opts, :url, :loader

    def initialize(root = Ro.config.root, options = {})
      @opts = Map.options_for(options)
      @root = Ro.fullpath(root)
      @url = Ro.normalize_url(opts[:url] || Ro.config.url)

      super(@root.to_s)

      Ro.error!("root=#{root.inspect} does not exist") unless test('d', self)
    end

    def root
      self
    end

    def load
      loader.load
    end

    def nodes
      Node::List.new(root) do |list|
        node_directories do |path|
          list.load(path)
        end
      end
    end

    def directories(&block)
      list = Dir.glob(File.join(root, '*/')).to_a.sort
      block ? list.each(&block) : list
    end

    def node_directories(&block)
      list = Dir.glob(File.join(root, '*/*/')).to_a.sort
      block ? list.each(&block) : list
    end
  end
end
