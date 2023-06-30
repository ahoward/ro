module Ro
  class Collection < BasicObject
    Ro = ::Ro
    Collection = ::Ro::Collection
    Path = ::Ro::Path
    Node = ::Ro::Node

    Kernel = ::Kernel
    StandardError = ::StandardError
    Array = ::Array
    Hash = ::Hash
    File = ::File
    Dir = ::Dir
    String = ::String
    Symbol = ::Symbol

    def self.new(*args, **kws)
      collection = allocate
      collection.send(:initialize, *args, **kws)
      collection
    end

    def send(*args, **kws, &block)
      Kernel.instance_method(:send).bind(self).call(*args, **kws, &block)
    end

    def collection
      self
    end

    attr_reader :root, :type, :id, :identifier, :nodes

    def initialize(root: Ro.config.root, type: nil, id: nil, nodes: nil, &block)
      @root = Root.for(root)
      @type = type
      @id = id

      Ro.error! "type=nil, id=#{@id}" if @type.nil? && @id

      @identifier = [@root, @type, @id].compact.join('/')

      @index = {}
      @method_missing = []

      @nodes = []

      if nodes
        nodes.each do |node|
          @nodes.push(Node.new(node.path, root: @root, collection: self))
        end
        @loaded = true
      else
        @loaded = false
      end

      return unless block

      load(&block)
    end

    def is_a?(other)
      Collection >= other.class
    end

    def class
      Collection
    end

    def delegate_to_nodes!(method, *args, &block)
      load

      result = @nodes.public_send(method, *args, &block)

      is_array_of_nodes = result.is_a?(Array) && !result.empty? && result.all? { |item| item.is_a?(Node) }

      # ::Kernel.p result: (result.is_a?(Array) && result.first.class)
      # ::Kernel.p is_array_of_nodes: is_array_of_nodes

      (
        if is_array_of_nodes
          Collection.new(root: @root, type: @type, id: @id, nodes: result)
        else
          result
        end
      )
    end

    def load(&block)
      return self if @loaded

      load!(&block)
    ensure
      @loaded = true
    end

    def load!
      prefix = @root

      suffix =
        if @type && @id
          "#{@type}/#{@id}/"
        elsif @type
          "#{@type}/*/"
        elsif @id
          Ro.error! "no type given with id=#{@id}"
        else
          '*/*/'
        end

      glob = File.join(prefix, suffix, 'attributes.yml').gsub(/[_-]/, '[_-]')

      # ::Kernel.p glob: glob

      directories = Dir.glob(glob) do |entry|
        path = File.dirname(entry)
        load_node!(path)
      end

      if @nodes.empty?
        if @type
          Ro.error!("no nodes found for type=#{@type}")
        else
          Ro.error!("no nodes found for glob=#{glob}")
        end
      end

      self
    end

    def reload(&block)
      @loaded = false
      load(&block)
    end

    def load_node!(path)
      node = Node.load(path, root: @root, collection: self)
      @nodes.push(node)
    end

    def [](*args, **kws, &block)
      load

      if args.size == 1 && [String, Symbol].include?(args.first.class)
        parts = Path.for(*args, **kws).parts
        method = parts.shift
        argv = parts
        send(method, *argv, **kws, &block)
      else
        super(*args, **kws, &block)
      end
    end

    include Pagination

    public_array_methods = Array.instance_methods(false)

    public_array_methods.each do |method|
      next if instance_methods.include?(method)

      # load
      # {@nodes}.public_send('#{method}', *args, &block)
      class_eval <<-____, __FILE__, __LINE__ + 1
        def #{method}(*args, &block)
          delegate_to_nodes!('#{method}', *args, &block)
        end
      ____
    end

    def method_missing(method, *args, &block)
      # ::Kernel.p 'method' => method, '@type' => @type, '@method_missing' => @method_missing
      if @method_missing.include?(method)
        @method_missing.clear

        begin
          super
        rescue StandardError => e
          e.set_backtrace((e.backtrace || [])[1..-1])
          Kernel.raise e
        end
      end

      @method_missing.push(method)

      begin
        if @nodes.respond_to?(method) #=> eg: ro.collection
          load

          result = @nodes.public_send(method, *args, &block)

          is_array_of_nodes = result.is_a?(Array) && !result.empty? && result.all? { |item| item.is_a?(Node) }

          return(
            if is_array_of_nodes
              Collection.new(root: @root, type: @type, id: @id, nodes: result)
            else
              result
            end
          )
        end

        if @type.nil? #=> eg: ro.collection.posts
          type = method
          Collection.new(root: @root, type: type)
        else #=> eg: ro.collection.posts.first_post
          type = @type
          id = method
          # ::Kernel.p '@type' => @type, 'id' => method
          Collection.new(root: @root, type: type, id: id).first
        end
      ensure
        @method_missing.pop
      end
    end
  end
end
