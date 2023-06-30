module Ro
  class Cache
    def self.storage
      Thread.current[:ro_cache] ||= Map.new
    end

    def storage
      Cache.storage
    end

    def [](key)
      storage.get(key)
    end

    def []=(key, value)
      storage[key] = value
    end

    def clear
      storage.clear
    end

    def fetch(key, &block)
      if storage.has?(key)
        storage.get(key)
      else
        value = block.call
        storage.set(key, value)
      end
    end

    def write(key, value)
      invalidate(key)
      storage.set(key => value)
    end

    def read(key, &block)
      if has?(key)
        storage.get(key)
      elsif block
        value = block.call
        storage.write(key, value)
      end
    end

    def invalidate(key)
      # prefix = Array(key).dup.tap { |array| array.pop }
      prefix = key[0..-2]
      storage.set(prefix, {})
    end

    def delete(*args, &block)
      invalidate(*args, &block)
    end
  end
end
