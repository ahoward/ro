module Ro
  class Root < ::String
    attr_reader :opts, :root, :url

    def self.for(arg)
      arg.is_a?(Root) ? arg : Root.new(arg)
    end

    def initialize(root = Ro.config.root, options = {})
      @root = Ro.realpath(root)
      @opts = Map.options_for(options)
      @url = Ro.normalize_url(opts[:url] || Ro.config.url)

      super(@root.to_s)
    ensure
      exists!
    end

    def exists!
      Ro.error!("root=#{root.inspect} does not exist") unless test('d', root)
    end

    def root
      self
    end

    def nodes
      Node::List.new(self) do |list|
        node_directories do |path|
          list.load(path)
        end
      end
    end

    def directories(&block)
      glob = File.join(self, '*/')
      list = Dir.glob(glob).to_a.sort
      block ? list.each(&block) : list
    end

    def node_directories(&block)
      glob = File.join(self, '*/*/')
      list = Dir.glob(glob).to_a.sort
      block ? list.each(&block) : list
    end
  end
end
