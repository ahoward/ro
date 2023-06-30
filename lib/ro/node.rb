module Ro
  class Node
    def self.load(*args, **kws, &block)
      new(*args, **kws, &block)
    end

    attr_reader :root, :collection, :path, :id, :slug, :type, :attributes

    def initialize(path, root: Ro.config.root, collection: nil)
      @path = Path.for(path).expand_path
      @id   = @path.basename
      @slug = Slug.for(@id)
      @type = @path.dirname.basename

      @root = Root.for(root)
      @collection = collection || Collection.new(root: @root, type: @type, id: @id)

      load!
    end

    def _type
      @type
    end

    def _id
      @id
    end

    def _path
      @path
    end

    def _slug
      @slug
    end

    def identifier
      File.join(@type, @id)
    end

    def inspect
      identifier
    end

    def to_s
      inspect
    end

    def node
      self
    end

    def get(*args)
      @attributes.get(*args)
    end

    def [](*args)
      @attributes.get(*args)
    end

    def asset_path(*_args)
      File.join(relative_path, 'assets')
    end

    def asset_dir
      File.join(path, 'assets')
    end

    def asset_paths
      Dir.glob("#{asset_dir}/**/**").select { |entry| test('f', entry) }.sort
    end

    def assets
      asset_paths.map { |path| Asset.new(node, path) }
    end

    def asset_urls
      assets.map(&:url)
    end

    def asset_for(*args)
      options = Map.options_for!(args)

      path_info = Path.relative(args)

      path = File.join(@path, 'assets', path_info)

      glob = path_info.gsub(/[_-]/, '[_-]')

      globs =
        [
          File.join(@path, 'assets', "#{glob}"),
          File.join(@path, 'assets', "#{glob}*"),
          File.join(@path, 'assets', "**/#{glob}*")
        ]

      candidates = globs.map { |glob| Dir.glob(glob, ::File::FNM_CASEFOLD) }.flatten.compact.uniq.sort

      case candidates.size
      when 0
        raise ArgumentError, "no asset matching #{globs.inspect}"
      else
        path = candidates.last
      end

      Asset.new(node, path)
    end

    def asset_for?(*args, &block)
      asset_for(*args, &block)
    rescue StandardError
      nil
    end

    def url_for(relative_path, options = {})
      raise ArgumentError, relative_path if Path.absolute?(relative_path)

      path = File.expand_path(File.join(node.path, relative_path.to_s))

      raise ArgumentError, "#{relative_path.inspect} -- DOES NOT EXIST" unless test('e', path)

      Ro.url_for(node.relative_path, relative_path.to_s, options)
    end

    def url(options = {})
      Ro.url_for(node.relative_path, options)
    end

    def relative_path
      @path.expand_path.relative_to(@root.expand_path)
    end

    def src_for(*args)
      key = Path.relative(:assets, :src, args).split('/')
      get(key)
    end

    def method_missing(method, *args, &block)
      super if method.to_s == 'to_ary'

      key = method.to_s
      data = Map.for(as_json)

      (
        if data.has_key?(key)
          data[key]
        else
          super
        end
      )
    end

    def as_json(*_args)
      attributes.to_hash.merge(meta_attributes)
    end

    def meta_attributes
      {
        '_' => {
          'type' => _type,
          'id' => _id,
          'identifier' => identifier,
          'url' => url,
        }
      }
    end

    def load!
      @attributes = Map.new

      _load_attributes_yml
      _load_attribute_files
      _load_assets

      @attributes.update(meta_attributes)
    end

    def _load_attributes_yml
      attributes_yml = File.join(@path, 'attributes.yml')

      cd = CycleDector.new(self)

      buf = IO.binread(attributes_yml)
      data = YAML.load(buf)
      data = data.is_a?(Hash) ? data : { '_' => data }

      @attributes.update(data)

      %w[assets].each do |key|
        raise ArgumentError, "attributes.yml may not contain the key '#{key}'" if @attributes.has_key?(key)
      end

      @attributes
    end

    def _load_attribute_files
      glob = File.join(@path, '**/**')
      cd = CycleDector.new(self)

      Dir.glob(glob) do |path|
        next if test('d', path)

        basename = File.basename(path)
        next if basename == 'attributes.yml'

        relative_path = Path.for(path).relative_to(@path)
        subdir = relative_path.split('/').first
        next if %w[assets].include?(subdir)

        path_info, ext = key = relative_path.split('.', 2)

        key = path_info.split('/')

        promise = cd.promise(key) do
          object = Ro.render(path, node)

          if object.is_a?(String)
            html = object
            html = Ro.expand_asset_urls(html, node)
          else
            object
          end
          # @attributes.set(key => html)
        end

        @attributes.set(key => promise)
      end

      cd.resolve.each do |key, value|
        @attributes.set(key => value)
      end
    end

    def _load_assets
      @attributes.set(assets: asset_attributes)
    end

    def asset_attributes
      {}.tap do |attributes|
        assets.each do |asset|
          key = asset.path.relative_to(asset_dir)
          value = { url: asset.url, src: asset.src }
          attributes.update(key => value)
        end
      end
    end
  end
end
