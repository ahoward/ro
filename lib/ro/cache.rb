module Ro
  class Cache < ::Map
    def write(key, value)
      invalidate(key)
      set(key => value)
    end

    def read(key, &block)
      if has?(key)
        get(key)
      else
        if block
          value = block.call
          write(key, value)
        else
          nil
        end
      end
    end

    def invalidate(key)
      prefix = Array(key).dup.tap{|array| array.pop}
      set(prefix, {})
    end
  end
end
