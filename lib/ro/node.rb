module Ro
  class Node
    include Klass

    attr_reader :path, :root

    def initialize(path)
      @path = Path.for(path)
      @root = Root.for(@path.parent.parent)
      @attributes = :lazyload
    end

    def name
      @path.name
    end

    def id
      name
    end

    def type
      @path.parent.name
    end

    def identifier
      File.join(type, id)
    end

    def inspect
      identifier
    end

    def collection
      @root.collection_for(type)
    end

    def attributes
      load_attributes
      @attributes
    end

    def load_attributes
      load_attributes! if @attributes == :lazyload
    end

    def load_attributes!
      @attributes = Map.new

      _load_base_attributes
      _load_asset_attributes
      _load_meta_attributes
      _load_file_attributes

      @attributes
    end

    def _load_base_attributes
      disallowed =
        %w[
          assets
          _meta
        ]

      glob =
        "attributes.{yml,yaml,json}"

      @path.glob(glob) do |file|
        attrs = _render(file)

        disallowed.each do |key|
          Ro.error!("#{ file } must not contain the key #{key.inspect}") if attrs.has_key?(key)
        end

        @attributes.update(attrs)
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
          identifier:,
          type:,
          id:,
          urls:
        )

        @attributes.set(_meta: hash)
      end
    end

    def _load_file_attributes
      ignored = _ignored_files

      @path.files.each do |file|
        next if ignored.include?(file)

        rel = file.relative_to(@path)

        key = rel.parts
        basename = key.pop
        base = basename.split('.', 2).first
        key.push(base)

        if @attributes.has?(key)
          raise Error.new("#{ @path } clobbers #{ key.inspect }!")
        end

        value = _render(file)

        @attributes.set(key => value)
      end
    end

    def _ignored_files
      ignored_files =
        %w[
          attributes.yml
          attributes.yaml
          attributes.json
          ./assets/**/**
        ].map do |glob|
          @path.glob(glob).select(&:file?)
        end

      ignored_files.flatten
    end

    def _render(file)
      value = Ro.render(file, _render_context)

      if value.is_a?(Ro::Template::HTML)
        html = value
        value = Ro.expand_asset_urls(html, self)
      end

      value
    end

    def _render_context
      to_hash.tap do |context|
        context[:ro] ||= root
        context[:collection] ||= collection
      end
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

      if attributes.has_key?(key)
        attributes[key]
      else
        super
      end
    end

    def to_hash
      attributes.to_hash
    end

    def to_s(...)
      to_json(...)
    end

    def to_json(...)
      JSON.pretty_generate(to_hash, ...)
    end

    def as_json(...)
      to_hash.as_json(...)
    end

    def to_yaml(...)
      to_hash.to_yaml(...)
    end

    def _mapify(data)
      converted = 'this_recursively_converts_nested_hashes_into_maps'

      Map.for(converted => data)[converted]
    end

    def files
      path.glob('**/**').select { |entry| entry.file? }.sort
    end

    def urls
      files.map { |file| url_for(file.relative_to(@path)) }.sort
    end

    def <=>(other)
      sort_key <=> other.sort_key
    end

    def sort_key
      default_sort_key
    end

    def default_sort_key
      position = (attributes[:position] ? Float(attributes[:position]) : 0.0)
      published_at = (attributes[:published_at] ? Time.parse(attributes[:published_at].to_s) : Time.at(0)).utc.iso8601
      created_at = (attributes[:created_at] ? Time.parse(attributes[:created_at].to_s) : Time.at(0)).utc.iso8601

      [position, published_at, created_at, name]
    end
  end
end
