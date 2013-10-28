module Ro
  class Node
    fattr :root
    fattr :path
    fattr :name
    fattr :type
    fattr :loaded

    def initialize(path)
      @path = Ro.realpath(path.to_s)
      @name = File.basename(@path)
      @type = File.basename(File.dirname(@path))
      @root = Ro::Root.new(File.dirname(File.dirname(@path)))
      @loaded = false
      @attributes = nil
      @in_method_missing = false
    end

    def id
      @name
    end

    def identifier
      "#{ type }/#{ name }"
    end

    def inspect
      #"#{ self.class.name }(#{ type }/#{ name })"
      identifier
    end

    def to_s
      inpsect
    end

    def basename
      name
    end

    def method_missing(method, *args, &block)
      Ro.log "Ro::Node(#{ identifier })#method_missing(#{ method.inspect }, #{ args.inspect })"

      in_method_missing = !!@in_method_missing

      return super if in_method_missing

      @in_method_missing = true

      _load do
        key = method.to_s

        return(
          if @attributes.has_key?(key)
            @attributes[key]
          else
            super
          end
        )
      end
    ensure
      @in_method_missing = in_method_missing
    end

    def attributes
      _load{ @attributes }
    end

    def instance_eval(*args, &block)
      _load{ super }
    end

    def related(*args, &block)
      _load{
        related = @attributes.get(:related) || Map.new
        nodes = List.new(root)
        list = root.nodes
        which = Coerce.list_of_strings(args) 

        related.each do |relationship, value|
          unless which.empty?
            next unless which.include?(relationship.to_s)
          end

          type, names =
            case value
              when Hash
                value.to_a.first
              else
                [relationship, value]
            end

          names = Coerce.list_of_strings(names)

          names.each do |name|
            identifier = "#{ type }/#{ name }"
            node = list.index[identifier]
            node._load{ nodes.add(node) }
          end
        end

        case
          when block.nil?
            nodes

          when block
            nodes.where(&block)
        end
      }
    end

    class Related
      fattr :attributes

      def initialize(attributes)
        @attributes = attributes
      end

      def all
        related = @attributes.get(:related) || Map.new
        names = related.keys
        self[names]
      end

      def [](name)
        name = File.basename(name.to_s)

        value = @attributes.get(:related, name)
        
        type, names =
          case value
            when Hash
              value.to_a.first
            else
              [name, value]
          end

        names = Array(names).flatten.compact.uniq

        list = ro[type]

        list.where(*names)
      end
    end

    def _load(&block)
      unless @loaded
        @loaded = _load_from_cache_or_disk
      end

      block ? block.call : @loaded
    end

    def _load_from_cache_or_disk
      cache_key = _cache_key

      cached = Ro.cache.read(cache_key)

      if cached
        Ro.log "loading #{ identifier } from cache"
        @attributes = Map.new.update(cached)
        :cache
      else
        Ro.log "loading #{ identifier } from disk"
        @attributes = Map.new
        _load_attributes_yml
        #_load_attribute_templates
        #_load_sources
        Ro.cache.write(cache_key, @attributes)
        :disk
      end
    end

    def _load_attributes_yml
      if test(?s, _attributes_yml)
        buf = IO.binread(_attributes_yml)
        data = YAML.load(buf)
        data = data.is_a?(Hash) ? data : {'_' => data}
        @attributes.update(data)
      end
    end

    def _cache_key
      glob = File.join(@path, '**/**')

      entries = []

      Dir.glob(glob) do |entry|
        stat =
          begin
            File.stat(entry)
          rescue
            next
          end

        timestamp = [stat.ctime, stat.mtime].max
        relative_path = Ro.relative_path(entry, :to => @path)
        entries.push([relative_path, timestamp.iso8601(2)]) 
      end

      signature = entries.map{|pair| pair.join('@')}.join(', ')

      md5 = Ro.md5(signature)

      "#{ @path }-#{ md5 }"
    end

    def _load_from_cache
      false
    end

    def _attributes_yml
      File.join(@path, 'attributes.yml')
    end
  end
end
