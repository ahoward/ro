module Ro
  class Node
    class << Node
      def for(arg, *args, **kws, &block)
        return arg if arg.is_a?(Node) && args.empty? && kws.empty? && block.nil?

        new(arg, *args, **kws, &block)
      end

      @@EXPAND_ASSET_URL_STRATEGIES = %i[accurate_expand_asset_urls sloppy_expand_asset_urls]

      def expand_asset_urls(html, node)
        last = @@EXPAND_ASSET_URL_STRATEGIES.size - 1

        @@EXPAND_ASSET_URL_STRATEGIES.each_with_index do |strategy, i|
          return send(strategy, html, node)
        rescue Object => e
          raise if i == last

          Ro.log(e)
        end

        Ro.error! "could not expand assets via #{@@EXPAND_ASSET_URL_STRATEGIES.join(', ')}"
      end

      def accurate_expand_asset_urls(html, node)
        doc = REXML::Document.new('<__ro__>' + html + '</__ro__>')

        doc.each_recursive do |element|
          next unless element.respond_to?(:attributes)

          src = {}
          element.attributes.each do |key, value|
            src[key] = value
          end

          dst = expand_asset_values(src, node)

          dst.each do |k, v|
            element.attributes[k] = v
          end
        end

        doc.to_s.tap do |xml|
          xml.sub!(/^\s*<.?__ro__>\s*/, '')
          xml.sub!(/\s*<.?__ro__>\s*$/, '')
          xml.strip!
        end
      end

      def sloppy_expand_asset_urls(html, node)
        html.to_s.gsub(%r{\s*=\s*['"](?:[.]/)?assets/[^'"\s]+['"]}) do |match|
          path = match[%r{assets/[^'"\s]+}]
          url = node.url_for(path)
          "='#{url}'"
        end
      end

      def expand_asset_values(hash, node)
        src = Map.for(hash)
        dst = Map.new

        re = %r{\A(?:[.]/)?(assets/[^\s]+)\s*\z}

        src.depth_first_each do |key, value|
          next unless value.is_a?(String)

          if (match = re.match(value.strip))
            path = match[1].strip
            url = node.url_for(path)
            value = url
          end

          dst.set(key, value)
        end

        dst.to_hash
      end
    end

    attr_reader :path, :root, :collection, :type, :name, :attributes

    def initialize(path, options = {})
      @path = Ro.path_for(path)
      @name = Ro.name_for(@path)

      @root = options.fetch(:root) { Root.for(@path.dirname.dirname) }
      @collection = options.fetch(:collection) { @root.collections[@path.dirname.basename] }

      @type = @collection.type

      load!
    end

    def id
      name
    end

    def identifier
      File.join(@collection.name, name)
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

      Ro.url_for(self.relative_path, relative_path, options)
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
      _load_file_attributes
      _load_asset_attributes
      _load_meta_attributes

      @attributes
    end

    def _load_attributes_yml
      attributes_yml = @path.join('attributes.yml')

      return unless test('e', attributes_yml)

      buf = IO.binread(attributes_yml)

      YAML.load(buf).tap do |data|
        attrs = Map.for(data.is_a?(Hash) ? data : { '_' => data })

        %w[assets _meta].each do |key|
          Ro.error!("attributes.yml may not contain the key #{key.inspect}") if attrs.has_key?(key)
        end

        @attributes.update(attrs)
      end
    end

    def _load_file_attributes
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
          value = Node.expand_asset_urls(html, node)
        end

        @attributes.set(key => value)
      end
    end

    def _load_asset_attributes
      {}.tap do |hash|
        assets.each do |asset|
          key = asset.name
          value = { url: asset.url, path: asset.path.relative_to(@root), src: asset.src }
          hash[key] = value
        end

        @attributes.set(assets: hash)
      end
    end

    def _load_meta_attributes
      {}.tap do |hash|
        hash.update(
          url: Ro.config.url,
          type:,
          id:,
          identifier:,
          urls:
        )

        @attributes.set(_meta: hash)
      end
    end

    def files
      path.glob('**/**').select { |entry| entry.file? }.sort
    end

    def urls
      files.map { |file| url_for(file.relative_to(@path)) }.sort
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
