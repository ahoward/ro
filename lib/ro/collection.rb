module Ro
  class Collection
    include Klass
    include Enumerable

    attr_reader :path, :root

    def initialize(path)
      @path = Path.for(path)
      @root = Root.for(@path.parent)
    end

    def name
      @path.name
    end

    def id
      name
    end

    def type
      name
    end

    def identifier
      type
    end

    def inspect
      identifier
    end

    def node_for(path)
      Node.new(path)
    end

    def subdirectories(...)
      @path.subdirectories(...)
    end

    def subdirectory_for(name)
      @path.subdirectory_for(name)
    end

    def each(offset:nil, limit:nil, &block)
      accum = []

      if offset
        i = -1
        n = 0
        subdirectories do |subdirectory|
          i += 1
          next if i < offset
          node = node_for(subdirectory)
          block ? block.call(node) : accum.push(node)
          n += 1
          break if limit && n >= limit
        end
      else
        subdirectories do |subdirectory|
          node = node_for(subdirectory)
          block ? block.call(node) : accum.push(node)
        end
      end

      block ? self : accum
    end

    class Page < ::Array
      attr_accessor :number

      def initialize(nodes = [], number: 1)
        replace(nodes)
        @number = number
      end
    end

    def page(number, size: 10)
      offset = [(number - 1), 0].max * size
      limit = [size, 1].max

      nodes = each(offset:, limit:)
      Page.new(nodes, number:)
    end

    def paginate(size: 10, &block)
      number = 0
      accum = []

      loop do
        number += 1
        page = self.page(number, size:)
        break if page.empty?
        block ? block.call(page) : accum.push(page)
      end

      block ? self : accum
    end

    def load(&block)
      n = 8
      q = Queue.new # FIXME
      o = Queue.new # FIXME

      producer =
        Thread.new do
          Thread.current.abort_on_exception = true

          subdirectories do |subdirectory|
            q.push(subdirectory)
          end
        end

      loaders =
        n.times.map do
          Thread.new do
            Thread.current.abort_on_exception = true

            loop do
              subdirectory = q.pop

              begin
                node = node_for(subdirectory)
                o.push(node)
              rescue => e
                o.push(e) # FIXME
                nil # FIXME
              end
            end
          end
        end

        accum = []

        consumer =
          Thread.new do
            Thread.current.abort_on_exception = true
              loop do
                node = o.pop
                block ? block.call(node) : accum.push(node)
              end
          end

        producer.join
        loaders.map{|loader| loader.join}
        consumer.join

        block ? self : accum
    end

    def to_array(...)
      each(...)
    end

    alias to_a to_array

    alias all to_array

    alias nodes to_array

    def first(*args)
      if args.size.zero?
        node_for(subdirectories.first)
      else
        subdirectories.first(*args).map{|subdirectory| node_for(subdirectory)}
      end
    end

    def last(*args)
      if args.size.zero?
        node_for(subdirectories.last)
      else
        subdirectories.last(*args).map{|subdirectory| node_for(subdirectory)}
      end
    end

    def size
      subdirectories.size
    end

    def paths_for(name)
      [
        subdirectory_for(name),
        subdirectory_for(Slug.for(name, :join => '-')),
        subdirectory_for(Slug.for(name, :join => '_')),
      ]
    end

    def get(name)
      paths_for(name).each do |path|
        next unless path.exist?

        return node_for(path)
      end

      nil
    end

    def [](name)
      get(name)
    end

    def slice(...)
      subdirectories.slice(...).map{|subdirectory| node_for(subdirectory)}
    end

    def method_missing(name, *args, **kws, &block)
      get(name) || super
    end
  end
end
