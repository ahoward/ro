module Ro
  class Collection
    include Enumerable

    class << Collection
      def child(ctor = nil, &block)
        @child = ctor if ctor
        @child = block if block
        @child
      end
    end

    attr_reader :path, :name, :child

    def initialize(path, options = {}, &block)
      @path = Path.for(path)
      @name = Ro.name_for(@path)
      child(options[:child] || self.class.child, &block)
      raise ArgumentError, 'no child' unless @child
    end

    def child(ctor = nil, &block)
      @child = ctor if ctor
      @child = block if block
      @child
    end

    def child_for(child)
      if @child.respond_to?(:call)
        @child.call(child)
      elsif @child.respond_to?(:new)
        @child.new(child)
      else
        Collection.new(child)
      end
    end

    def subdirectories(&block)
      [].tap do |accum|
        @path.glob('*') do |entry|
          next unless entry.directory?

          subdirectory = entry
          accum.push(block ? block.call(subdirectory) : subdirectory)
        end
      end
    end

    def each(&block)
      [].tap do |accum|
        subdirectories do |subdirectory|
          child = child_for(subdirectory)
          accum.push(block ? block.call(child) : child)
        end
      end
    end

    def subdirectory_for(name)
      subdirectories.detect { |subdirectory| Ro.name_for(subdirectory) == Ro.name_for(name) }
    end

    def get(name)
      subdirectory = subdirectory_for(name)
      raise(IndexError, name.inspect) unless subdirectory

      child_for(subdirectory)
    end

    alias [] get

    def method_missing(name, *args, &block)
      get(name)
    rescue IndexError
      super
    end
  end
end
