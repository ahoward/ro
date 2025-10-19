module Ro
  class Node
    include Klass

    attr_reader :path, :root, :metadata_file

    # T023: Updated to accept (collection, metadata_file) for new structure
    def initialize(collection_or_path, metadata_file = nil)
      if metadata_file
        # New structure: collection + metadata_file
        @collection = collection_or_path
        @metadata_file = Path.for(metadata_file)

        # Raise error if metadata file doesn't exist
        unless @metadata_file.exist?
          raise Errno::ENOENT, "No such file or directory - #{@metadata_file}"
        end

        @root = @collection.root

        # Derive node ID from metadata filename (without extension)
        # T025: ID derived from metadata filename
        node_id = @metadata_file.basename.to_s.sub(/\.(yml|yaml|json|toml)$/, '')

        # Path is the node directory (sibling to metadata file)
        @path = @collection.path.join(node_id)
      else
        # Old structure compatibility: just a path
        @path = Path.for(collection_or_path)
        @root = Root.for(@path.parent.parent)
        @metadata_file = nil
      end

      @attributes = :lazyload
    end

    def name
      if @metadata_file
        # T025: For new structure, name comes from metadata filename
        @metadata_file.basename.to_s.sub(/\.(yml|yaml|json|toml)$/, '')
      else
        @path.name
      end
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
      @collection || @root.collection_for(type)
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
      _load_file_attributes
      _load_asset_attributes
      _load_meta_attributes

      @attributes
    end

    # T026: Modified to load from external metadata_file (new structure)
    def _load_base_attributes
      if @metadata_file && @metadata_file.exist?
        # New structure: load from explicit metadata file
        attrs = _render(@metadata_file)
        update_attributes!(attrs, file: @metadata_file)
      else
        # Old structure: search for attributes.yml in node directory
        glob = "attributes.{yml,yaml,json}"

        @path.glob(glob) do |file|
          attrs = _render(file)
          update_attributes!(attrs, file:)
        end
      end
    end

    def _load_asset_attributes
      {}.tap do |hash|
        assets.each do |asset|
          key = asset.name
          url = asset.url
          path = asset.path.relative_to(@root)
          src = asset.src
          img = asset.img
          size = asset.size

          value = { url:, path:, size:, img:, src: }

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
          urls:,
          created_at:,
          updated_at:,
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

        value = _render(file)

        if value.is_a?(HTML)
          attrs = value.front_matter
          update_attributes!(attrs, file:)
        end

        if @attributes.has?(key)
          raise Error.new("path=#{ @path.inspect } masks #{ key.inspect } in #{ @attributes.inspect }!")
        end

        @attributes.set(key => value)
      end
    end

    def update_attributes!(attrs = {}, **context)
      attrs = Map.for(attrs)

      blacklist = %w[
        assets
        _meta
      ]

      blacklist.each do |key|
        if attrs.has_key?(key)
          Ro.error!("#{ key } is blacklisted!", **context)
        end
      end

      keys = @attributes.depth_first_keys

      attrs.depth_first_keys.each do |key|
        if keys.include?(key)
          Ro.error!("#{ attrs.inspect } clobbers #{ @attributes.inspect }!", **context)
        end
      end

      @attributes.update(attrs)
    end

    # T028: Updated ignore patterns for new structure
    def _ignored_files
      # Both old and new structure: ignore attributes files and assets/ subdirectory
      ignored_files =
        %w[
          attributes.yml
          attributes.yaml
          attributes.json
          ./assets/**/**
        ].map do |glob|
          @path.glob(glob).select(&:file?)
        end.flatten
    end

    def _render(file)
      node = self

      value = Ro.render(file, _render_context)

      if value.is_a?(HTML)
        front_matter = value.front_matter
        html = Ro.expand_asset_urls(value, node)
        value = HTML.new(html, front_matter:)
      end

      if value.is_a?(Hash)
        attributes = value
        value = Ro.expand_asset_values(attributes, node)
      end

      value
    end

    def _render_context
      to_hash.tap do |context|
        context[:ro] ||= root
        context[:collection] ||= collection
      end
    end

    def fetch(*args)
      attributes.fetch(*args)
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

    # T027: Updated to return assets/ subdirectory in both old and new structure
    def asset_dir
      # Both old and new structure use assets/ subdirectory
      # This prevents files from being rendered as templates
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
      Ro.url_for(self.relative_path, relative_path, options)
    end

    def path_for(...)
      @path.join(...)
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

    def to_str(...)
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

    def created_at
      files.map{|file| File.stat(file).ctime}.min
    end

    def updated_at
      files.map{|file| File.stat(file).mtime}.max
    end
  end
end
