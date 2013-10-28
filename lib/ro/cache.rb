module Ro
  class Cache < ::Hash
    def write(key, value)
      self[key] = value
    end

    def read(key, &block)
      if has_key?(key)
        self[key]
      else
        if block
          value = block.call
          write(key, value)
        else
          nil
        end
      end
    end
  end
end
