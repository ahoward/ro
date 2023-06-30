module Ro
  class Root < Path
    attr_reader :url

    def initialize(root = Ro.config.root, options = {})
      @options = Map.for(options)

      super(root)

      @url = Ro.normalize_url(@options[:url] || Ro.config.url)

      exists!
    end

    def exists!
      Ro.error!("root=#{expand_path} is not as a directory") unless exist? && directory?
    end

    def collection
      Collection.new(root: self)
    end

    #     # FIXME
    #     def nodes
    #       Node::List.new(self) do |list|
    #         node_directories do |path|
    #           list.load(path)
    #         end
    #       end
    #     end
    #
    #     def directories(&block)
    #       glob = File.join(self, '*/')
    #       list = Dir.glob(glob).to_a.sort
    #       block ? list.each(&block) : list
    #     end
    #
    #     def node_directories(&block)
    #       glob = File.join(self, '*/*/')
    #
    #       directories = Dir.glob(glob).to_a.select do |entry|
    #         Path.for(entry).exist? && Path.for(entry, 'attributes.yml').exist?
    #       end
    #
    #       directories.sort!
    #
    #       block ? directories.each(&block) : directories
    #     end
  end
end
