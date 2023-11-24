module Ro
  class Node
    class << Node
      def for(arg, *args, **kws, &block)
        return arg if arg.is_a?(Node) && args.empty? && kws.empty? && block.nil?

        new(arg, *args, **kws, &block)
      end
    end

    attr_reader :path, :root, :type, :name, :attributes

    def initialize(path, options = {})
      @path = Ro.path_for(path)

      @root = options.fetch(:root) { Root.for(@path.dirname.dirname) }

      @type = @path.dirname.basename
      @name = @path.basename

      @attributes = Map.new

      load!
    end

    def identifier
      File.join(type, name)
    end

    def inspect(...)
      attributes.inspect(...)
    end

    def to_s
      inspect
    end

    def get(*args)
      attributes.get(*args)
    end

    def [](*args)
      attributes.get(*args)
    end

    def relative_path
      path.relative_to(root)
    end

    def asset_dir
      path.join('assets')
    end

    def asset_paths
      asset_dir.select { |entry| entry.file? }.sort
    end

    def assets
      asset_paths.map { |path| Asset.for(path, node: self) }
    end

    def asset_urls
      assets.map(&:url)
    end

    def asset_for(*args)
      options = Map.options_for!(args)

      path_info = Path.relative(args)

      path = @path.join('assets', path_info)

      glob = path_info.gsub(/[_-]/, '[_-]')

      globs =
        [
          @path.call('assets', "#{glob}"),
          @path.call('assets', "#{glob}*"),
          @path.call('assets', "**/#{glob}*")
        ]

      candidates = globs.map { |glob| Dir.glob(glob, ::File::FNM_CASEFOLD) }.flatten.compact.uniq.sort

      case candidates.size
      when 0
        raise ArgumentError, "no asset matching #{globs.inspect}"
      else
        path = candidates.last
      end

      Asset.for(path, node: self)
    end

    def asset_for?(*args, &block)
      asset_for(*args, &block)
    rescue StandardError
      nil
    end

    def url_for(relative_path, options = {})
      raise ArgumentError, relative_path if Path.absolute?(relative_path)

      fullpath = Path.for(path, relative_path).expand

      raise ArgumentError, "#{relative_path.inspect} -- DOES NOT EXIST" unless fullpath.exist?

      Ro.url_for(self.relative_path, relative_path.to_s, options)
    end

    def url(options = {})
      Ro.url_for(relative_path, options)
    end

    def src_for(*args)
      key = Path.relative(:assets, :src, args).split('/')
      get(key)
    end

    def method_missing(method, *args, &block)
      key = method.to_s

      if @attributes.has_key?(key)
        @attributes[key]
      else
        super
      end
    end

    def to_hash
      attributes.to_hash
    end

    def load!
      @attributes = Map.new

      _load_attributes_yml
      _load_attribute_files
      _load_assets
      _load_meta_attributes

      @attributes
    end

    def _load_attributes_yml
      attributes_yml = @path.join('attributes.yml')

      return unless test('e', attributes_yml)

      buf = IO.binread(attributes_yml)

      YAML.load(buf).tap do |data|
        hash = data.is_a?(Hash) ? data : { '_' => data }

        @attributes.update(hash)

        %w[assets].each do |key|
          Ro.error!("attributes.yml may not contain the key #{key.inspect}") if @attributes.has_key?(key)
        end
      end
    end

    def _load_attribute_files
      @path.glob do |path|
        next if test('d', path)

        basename = path.basename
        next if basename == 'attributes.yml'

        relative_path = Path.for(path).relative_to(@path)
        subdir = relative_path.split('/').first
        next if %w[assets].include?(subdir)

        path_info, ext = key = relative_path.split('.', 2)
        key = path_info.split('/')

        value = Ro.render(path, self)

        if value.is_a?(Ro::Template::HTML)
          html = value
          node = self
          value = Ro.expand_asset_urls(html, node)
        end

        @attributes.set(key => value)
      end
    end

    def _load_assets
      {}.tap do |hash|
        assets.each do |asset|
          key = asset.name
          value = { url: asset.url, path: asset.path, src: asset.src }
          hash[key] = value
        end

        @attributes.set(assets: hash)
      end
    end

    def _load_meta_attributes
      {}.tap do |meta|
        meta.update(
          url: url,
          type: type,
          name: name,
          identifier: identifier
        )

        @attributes.set(_meta: meta)
      end
    end

    def binding
      super
    end

    def <=>(other)
      sort_key <=> other.sort_key
    end

    def sort_key
      position = (attributes[:position] ? Float(attributes[:position]) : 0.0)
      published_at = (attributes[:published_at] ? Time.parse(attributes[:published_at].to_s) : Time.at(0)).utc.iso8601
      created_at = (attributes[:created_at] ? Time.parse(attributes[:created_at].to_s) : Time.at(0)).utc.iso8601
      [position, published_at, created_at, name]
    end
  end
end
