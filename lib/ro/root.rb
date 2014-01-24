module Ro
  class Root < ::String
    def initialize(root)
      super(Ro.realpath(root.to_s))
    ensure
      raise ArgumentError.new("root=#{ root.inspect }") if root.nil?
      raise ArgumentError.new("root=#{ root.inspect }") unless test(?d, root)
    end

    def root
      self
    end

    def nodes
      Node::List.new(root) do |list|
        node_directories do |path|
          list.load(path)
        end
      end
    end

    def directories(&block)
      Dir.glob(File.join(root, '*/'), &block)
    end

    def node_directories(&block)
      Dir.glob(File.join(root, '*/*/'), &block)
    end

    def git
      @git ||= Git.new(self)
    end

    def transaction(*args, &block)
      git.transaction(*args, &block)
    end

    def lock(&block)
      @lock ||= Lock.new(File.join(self, '.lock'))
      block ? @lock.lock(&block) : @lock
    end
  end
end
