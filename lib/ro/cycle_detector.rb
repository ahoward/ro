module Ro
  class CycleDector
    def self.scope_for(*args)
      [args].flatten.compact.join('/').strip
    end

    def self.promise(*args, &block)
      new(scope).promise(*args, &block)
    end

    attr_accessor :scope, :promises, :keys

    def initialize(scope = :cycle_detector)
      @scope = CycleDector.scope_for(scope)
      @promises = []
      @keys = []
    end

    def scope(*args, &block)
      if args.empty? && block.nil?
        @scope
      else
        scope = CycleDector.scope_for(@scope, *args)
        CycleDector.new(scope, &block)
      end
    end

    def promise(key = :promise, &block)
      promise = Promise.new(cd, key, &block)
    ensure
      keys.push(key)
      promises.push(promise)
    end

    def resolve
      Map.new.tap do |result|
        keys.zip(promises).each do |key, promise|
          value = promise.resolve
          result.set(key => value)
        end
      end
    end

    class Promise < BasicObject
      def initialize(cd, key = :promise, &block)
        @cd = cd
        @key = key
        @block = block
        @resolvable = false
        @resolved = nil
      end

      def method_missing(method, *args, &block)
        resolve if @resolvable && !@resolved
        super unless @resolved
        @result.send(method, *args, &block)
      end

      def is_a?(other)
        other.instance_of?(Promise)
      end

      def resolves!
        @resolvable = true
      end

      def resolve
        return @result if @resolved

        if @cd.key.include?(@key)
          cycle = @cd.key + [@key]
          scope = @cd.scope
          ::Ro.error! "cycle `#{cycle.join ' -> '}` detected resolving `#{scope}`"
        end

        @cd.key.push(@key)

        begin
          @result = @block.call
        ensure
          @resolved = true
          @cd.key.pop
        end
      end

      def to_s
        resolve
      end

      def inspect
        resolve
      end

      def call
        resolve
      end
    end
  end
end
