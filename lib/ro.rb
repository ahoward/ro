require_relative 'ro/_lib'

Ro.load_dependencies!

module Kernel
  def ro(*args, &block)
    Ro.collection(*args, &block)
  end
end

module Ro
  # node utils
  # |
  # v
  def self.collection(*args, &block)
    root(*args, &block).collection
  end

  def self.root(*args, &block)
    Ro::Root.new(*args, &block)
  end

  def self.root=(root)
    ENV['RO_ROOT'] = root.to_s
  end

  # config
  # |
  # v
  def self.default
    Map.for({
              root: './ro',
              url: '/ro',
              path: './ro:./public/ro',
              debug: '',
              log: 'false'
            })
  end

  def self.env
    Map.for({
              root: ENV['RO_ROOT'],
              url: ENV['RO_URL'],
              path: ENV['RO_PATH'],
              debug: ENV['RO_DEBUG'],
              log: ENV['RO_LOG']
            })
  end

  def self.config
    string = proc { |value| String(value) }
    url = proc { |value| Ro.normalize_url(value) }
    array = proc { |value| String(value).scan(/[^,:]+/) }
    bool = proc { |value| String(value) !~ /^\s*(f|false|off|no|0){0,1}\s*$/ }

    root = string[Ro.env.root || Ro.default.root]
    url = url[Ro.env.url || Ro.default.url]
    path = array[Ro.env.path || Ro.default.path]
    debug = bool[Ro.env.debug || Ro.default.debug]
    log = bool[Ro.env.log || Ro.default.log]

    Map.for({
              root: root,
              url: url,
              path: path,
              debug: debug,
              log: log
            })
  end

  # url utils
  # |
  # v

  def self.url_for(path, *args)
    options = Map.extract_options!(args)
    base = options[:base] || options[:url] || Ro.config.url

    path = Path.for(path, *args)

    fragment = options.delete(:fragment)
    query = options.delete(:query) || options

    uri = URI.parse(base.to_s)
    uri.path = Path.absolute(uri.path, path)
    uri.path = '' if uri.path == '/'

    uri.query = Ro.query_string_for(query) unless query.empty?

    uri.fragment = fragment if fragment

    uri.to_s
  end

  def self.query_string_for(hash, options = {})
    options = Map.for(options)
    escape = options.has_key?(:escape) ? options[:escape] : true
    pairs = []
    esc = escape ? proc { |v| CGI.escape(v.to_s) } : proc { |v| v.to_s }
    hash.each do |key, values|
      key = key.to_s
      values = [values].flatten
      values.each do |value|
        value = value.to_s
        pairs << if value.empty?
                   [esc[key]]
                 else
                   [esc[key], esc[value]].join('=')
                 end
      end
    end
    pairs.replace(pairs.sort_by { |pair| pair.size })
    pairs.join('&')
  end

  def self.normalize_url(url)
    uri = URI.parse(url.to_s).normalize
    uri.path = Path.absolute(uri.path)
    uri.to_s
  end

  # misc utils
  # |
  # v
  def self.cache
    Thread.current[:RO_CACHE] ||= Cache.new
  end

  def self.md5(string)
    Digest::MD5.hexdigest(string)
  end

  # log utils
  # |
  # v
  def self.logger
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.log(*args, &block)
    level = nil

    level = if args.size == 0 || args.size == 1
              :info
            else
              args.shift.to_s.to_sym
            end

    @logger && @logger.send(level, *args, &block)
  end

  def self.log!
    Ro.logger =
      ::Logger.new(STDERR).tap do |logger|
        logger.level = ::Logger::INFO
      end
  end

  def self.debug!
    Ro.logger =
      ::Logger.new(STDERR).tap do |logger|
        logger.level = ::Logger::DEBUG
      end
  end

  def self.error!(message, context = nil)
    error = Error.new(message, context)

    begin
      raise error
    rescue Error
      backtrace = error.backtrace || []
      error.set_backtrace(backtrace[1..-1])
      raise
    end
  end

  # name utils
  # |
  # v
  def self.slug_for(*args, &block)
    options = Map.options_for!(args)
    options[:join] = '-' unless options.has_key?(:join)
    args.push(options)
    Slug.for(*args, &block)
  end

  def self.name_for(*args, &block)
    options = Map.options_for!(args)
    options[:join] = '_' unless options.has_key?(:join)
    args.push(options)
    Slug.for(*args, &block)
  end

  # template utils
  # |
  # v
  def self.template(method = :tap, *args, &block)
    Template.send(method, *args, &(block || proc {}))
  end

  def self.render(path, context)
    Template.render(path, context: context)
  end

  def self.render_src(path, context)
    Template.render_src(path, context: context)
  end

  # url expansion utils
  # |
  # v
  def self.expand_asset_values(hash, node)
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

  def self.expand_asset_urls(html, node)
    accurate_expand_asset_urls(html, node)
  rescue Object => e
    Ro.log(e)
    sloppy_expand_asset_urls(html, node)
  end

  def self.accurate_expand_asset_urls(html, node)
    doc = REXML::Document.new('<__ml__>' + html + '</__ml__>')

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

    doc.to_s.tap do |ml|
      ml.sub!(/^\s*<.?__ml__>\s*/, '')
      ml.sub!(/\s*<.?__ml__>\s*$/, '')
      ml.strip!
    end
  end

  def self.sloppy_expand_asset_urls(html, node)
    html.to_s.gsub(%r{\s*=\s*['"](?:[.]/)?assets/[^'"\s]+['"]}) do |match|
      path = match[%r{assets/[^'"\s]+}]
      url = node.url_for(path)
      "='#{url}'"
    end
  end

  # coercison utils
  # |
  # v
  def self.list_of_strings(*args)
    args.join(',').scan(/[^,\s]+/)
  end

  # init
  # |
  # v
  def self.initialize!
    Ro.load %w[
      slug.rb
      path.rb
      error.rb
      cache.rb
      template.rb
      pagination.rb
      cycle_detector.rb
      root.rb
      node.rb
      collection.rb
      asset.rb
      model.rb
    ]

    Ro.log! if Ro.config.log
    Ro.debug! if Ro.config.debug
  end
end

Ro.initialize!
