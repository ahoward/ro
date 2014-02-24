module Ro
  class Node
    fattr :root
    fattr :path
    fattr :type
    fattr :loaded
    fattr :fields

    def initialize(path)
      @path = Ro.realpath(path.to_s)
      @id   = File.basename(@path)
      @slug = Slug.for(@id)
      @type = File.basename(File.dirname(@path))
      @root = Ro::Root.new(File.dirname(File.dirname(@path)))
      @loaded = false
      @loading = false
      @attributes = Map.new
      @fields = Map.new
    end

    def id
      @id
    end

    def _id
      @id
    end

    def type
      attributes[:type] || @type
    end

    def _type
      @type
    end

    def path
      attributes[:path] || @path
    end

    def _path
      @path
    end

    def slug
      attributes[:slug] || @slug
    end

    def _slug
      @slug
    end

    def identifier
      "#{ _type }/#{ _id }"
    end

    def hash
      identifier.hash
    end

    def ==(other)
      attributes == other.attributes
    end

    def inspect
      identifier
    end

    def to_s
      inspect
    end

    def basename
      name
    end

    def node
      self
    end

    def get(*args)
      attributes.get(*args)
    end

    def [](*args)
      attributes.get(*args)
    end

    def asset_path(*args, &block)
      File.join(relative_path, 'assets')
    end

    def asset_dir
      File.join(path, 'assets')
    end

    def asset_paths
      Dir.glob("#{ asset_dir }/**/**").select{|entry| test(?f, entry)}
    end

    def assets
      asset_paths.map do |path|
        name = path.sub(asset_dir + "/", "")
        path_info = path.gsub(/^#{ Regexp.escape(Ro.root) }/, '')
        url = File.join(Ro.route, path_info)
        Asset.new(name, :path => path, :url => url)
      end
    end

    def asset_urls
      assets.map(&:url)
    end

    def asset_for(*args, &block)
      options = Map.options_for!(args)

      path_info = Ro.relative_path_for(args)

      path = File.join(@path.to_s, 'assets', path_info)

      glob = path_info.gsub(/[_-]/, '[_-]')

      globs = 
        [
          File.join(@path.to_s, 'assets', "#{ glob }"),
          File.join(@path.to_s, 'assets', "#{ glob }*"),
          File.join(@path.to_s, 'assets', "**/#{ glob }*")
        ]

      candidates = globs.map{|glob| Dir.glob(glob, ::File::FNM_CASEFOLD)}.flatten.compact.uniq

      case candidates.size
        when 0
          raise ArgumentError.new("no asset matching #{ globs.inspect }")
        else
          path = candidates.first
          name = path.sub(asset_dir + "/", "")
          path_info = path.gsub(/^#{ Regexp.escape(Ro.root) }/, '')
          url = File.join(Ro.route, path_info)
      end

      Asset.new(name, :path => path, :url => url)
    end

    def asset_for?(*args, &block)
      begin
        asset_for(*args, &block)
      rescue
        nil
      end
    end

    class Asset < ::String
      fattr(:path)
      fattr(:url)

      def initialize(name, options = {})
        super(name)
      ensure
        options = Map.for(options)

        Asset.fattrs.each do |attr|
          if options.has_key?(attr)
            value = options[attr]
            send(attr, value)
          end
        end
      end

      def name
        self
      end

      IMAGE_RE = %r/[.](jpg|jpeg|png|gif|tif|tiff)$/i

      def image?
        !!(self =~ IMAGE_RE)
      end

      def extension
        base, ext = basename.split('.', 2)
        ext
      end
      alias_method(:ext, :extension)

      def basename
        File.basename(path.to_s)
      end
    end

    def url_for(*args, &block)
      options = Map.options_for!(args)

      opts = Map.new

      opts[:timestamp] = options.delete(:timestamp)

      args.push(options)

      asset = asset_for(*args, &block)

      if ts = opts.delete(:timestamp)
        if ts == true
          opts[:_] = File.stat(asset.path).mtime.utc.to_i
        else
          opts[:_] = ts
        end
      end

      if opts.empty?
        asset.url
      else
        query_string = Ro.query_string_for(opts)
        "#{ asset.url }?#{ query_string }"
      end
    end

    def url_for?(*args, &block)
      begin
        url_for(*args, &block)
      rescue
        nil
      end
    end

    def source_for(*args)
      key = Ro.relative_path_for(:assets, :source, args).split('/')
      get(key)
    end

    def route(*args)
      path_info = Ro.absolute_path_for(Ro.route, relative_path)
      [Ro.asset_host, path_info].compact.join('/')
    end

    def relative_path
      re = /^#{ Regexp.escape(Ro.root) }/
      @path.to_s.gsub(re, '')
    end

    def method_missing(method, *args, &block)
      super if method.to_s == 'to_ary'

      Ro.log "Ro::Node(#{ identifier })#method_missing(#{ method.inspect }, #{ args.inspect })"

      key = method.to_s

      if @attributes.has_key?(key)
        return @attributes[key]
      end

      _load do
        return(
          if @attributes.has_key?(key)
            @attributes[key]
          else
            super
          end
        )
      end
    end

    def attributes
      _load{ @attributes }
    end

    def attributes=(attributes)
      @attributes = attributes
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

    def reload(&block)
      @loaded = false
      _load(&block)
    end

    def loaded
      attributes
    end

    def load!(&block)
      _load(&block)
    end

    def _load(&block)
      unless @loaded
        if @loading
          return(block ? block.call : :loading)
        end

        @loading = true
        @loaded = _load_from_cache_or_disk
        @loading = false
      end

      block ? block.call : @loaded
    end

    def _load_from_cache_or_disk
      cache_key = _cache_key

      cached = Ro.cache.read(cache_key)

      if cached
        Ro.log "loading #{ identifier } from cache"

        @attributes = Map.new.update(cached)

        return :cache
      else
        Ro.log "loading #{ identifier } from disk"

        @attributes = Map.new

        _load_attributes_yml
        _load_attribute_files
        _load_sources
        _load_assets

        Ro.cache.write(cache_key, @attributes)

        return :disk
      end
    end

    def _load_attributes_yml
      if test(?s, _attributes_yml)
        buf = IO.binread(_attributes_yml)
        data = YAML.load(buf)
        data = data.is_a?(Hash) ? data : {'_' => data}

        @attributes.update(data)

        %w( assets ).each do |key|
          raise ArgumentError.new("attributes.yml may not contain the key '#{ key }'") if @attributes.has_key?(key)
        end

        @attributes
      end
    end

    def _load_attribute_files
      glob = File.join(@path, '**/**')
      node = self

      Dir.glob(glob) do |path|
        next if test(?d, path)

        basename = File.basename(path)
        next if basename == 'attributes.yml'

        relative_path = Ro.relative_path(path, :to => @path)
        next if relative_path =~ /^assets\//

        key = relative_path.split('.', 2).first.split('/')

        html = Ro.render(path, node)
        html = Ro.expand_asset_urls(html, node)

        @attributes.set(key => html)
      end
    end

    def _load_sources
      glob = File.join(@path, 'assets/source/*')
      node = self

      Dir.glob(glob) do |path|
        next if test(?d, path)

        basename = File.basename(path)
        key, ext = basename.split('.', 2)

        next if basename == 'attributes.yml'

        value = Ro.render_source(path, node)
        @attributes.set([:assets, :source, basename] => value)
      end
    end

    def _load_assets
      glob = File.join(@path, 'assets/**/**')
      node = self

      Dir.glob(glob) do |path|
        next if test(?d, path)

        relative_path = Ro.relative_path(path, :to => "#{ @path }/assets")

        url = url_for(relative_path)
        key = relative_path.split('/')

        key.unshift('urls')

        @attributes.set(key => url)
      end
    end

    def _binding
      Kernel.binding
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

      fingerprint = entries.map{|pair| pair.join('@')}.join(', ')

      md5 = Ro.md5(fingerprint)

      [@path, md5]
    end

    def _load_from_cache
      false
    end

    def _attributes_yml
      File.join(@path, 'attributes.yml')
    end
  end
end
