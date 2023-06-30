class CycleDector
  attr_accessor :context, :promises, :keys, :key

  def initialize(context)
    @context = context
    @promises = []
    @keys = []
    @key = []
  end

  def cd
    self
  end

  def promise(key, &block)
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
    def initialize(cd, key, &block)
      @cd = cd
      @key = key
      @block = block
      @resolved = nil
    end

    def method_missing(method, *args, &block)
      super unless @resolved
      @resolved.send(method, *args, &block)
    end

    def is_a?(other)
      other.instance_of?(Promise)
    end

    def resolve
      return @resolved if @resolved

      if @cd.key.include?(@key)
        cycle = @cd.key + [@key]
        ::Ro.error! "rendering #{@cd.context.identifier} cycles on `#{cycle.join ' -> '}`"
      end

      @cd.key.push(@key)

      begin
        @resolved = @block.call.to_s
      ensure
        @cd.key.pop
      end
    end

    def call
      resolve
    end

    def to_s
      resolve
    end

    def inspect
      resolve
    end
  end
end
