module Ro
  class Promise < BasicObject
    def initialize(&block)
      @_thread =
        ::Thread.new do
          ::Thread.current.abort_on_exception = true

          block.call
        end
    end

    def _thread
      @_thread
    end

    def _value
      _thread.value
    end

    def method_missing(method, *args, **kws, &block)
      @_thread.value.send(method, *args, **kws, &block)
    end
  end
end
