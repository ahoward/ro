module Ro
  module Methods
    # cast methods
    # |
    # v
    def cast(which, arg, *args)
      which = which.to_s
      values = [arg, *args].join(',').scan(/[^,\s]+/)

      list_of = which.match(/^list_of_(.+)$/)
      which = list_of[1] if list_of

      cast = casts.fetch(which.to_s.to_sym)

      if list_of
        values.map { |value| cast[value] }
      else
        raise ArgumentError, "too many values in #{values.inspect}" if values.size > 1

        value = values.first
        cast[value]
      end
    end

    def casts
      {
        :string        => proc { |value| String(value) },
        :int           => proc { |value| Integer(value.to_s) },
        :string_or_nil => proc { |value| String(value).empty? ? nil : String(value) },
        :url           => proc { |value| Ro.normalize_url(value) },
        :array         => proc { |value| String(value).scan(/[^,:]+/) },
        :bool          => proc { |value| String(value) !~ /^\s*(f|false|off|no|0){0,1}\s*$/ },
        :path          => proc { |value| Path.for(value) },
        :path_or_nil   => proc { |value| String(value).empty? ? nil : Path.for(value) },
        :root          => proc { |value| Root.for(value) },
        :time          => proc { |value| Time.parse(value.to_s) },
        :date          => proc { |value| Date.parse(value.to_s) },
      }
    end

    def mapify(pod)
      Map.for(:pod => pod)[:pod]
    end

    def pod(object)
      JSON.parse(object.to_json)
    end

    # url methods
    # |
    # v
    def url_for(path, *args)
      options = Map.extract_options!(args)

      base = (options.delete(:base) || options.delete(:url))

      path = Path.for(path, *args)

      base ||= (
        if Ro.is_image?(path)
          Ro.config.img_url
        else
          Ro.config.url
        end
      )

      fragment = options.delete(:fragment)
      query = options.delete(:query) || options

      uri = URI.parse(base.to_s)
      uri.path = Path.for(uri.path, path).absolute
      uri.path = '' if uri.path == '/'

      uri.query = query_string_for(query) unless query.empty?
      uri.fragment = fragment unless fragment.nil?

      uri.to_s
    end

    def query_string_for(hash, options = {})
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

    def normalize_url(url)
      uri = URI.parse(url.to_s).normalize
      uri.path = Path.for(uri.path).absolute
      uri.to_s
    end

    # log methods
    # |
    # v
    attr_accessor :logger

    def log(*args, &block)
      level = nil

      level = if args.size == 0 || args.size == 1
                :info
              else
                args.shift.to_s.to_sym
              end

      @logger && @logger.send(level, *args, &block)
    end

    def log!
      Ro.logger =
        ::Logger.new(STDERR).tap do |logger|
          logger.level = ::Logger::INFO
        end
    end

    def debug!
      Ro.logger =
        ::Logger.new(STDERR).tap do |logger|
          logger.level = ::Logger::DEBUG
        end
    end

    def error!(message, context = nil)
      error = Error.new(message, context)

      begin
        raise error
      rescue Error
        backtrace = error.backtrace || []
        error.set_backtrace(backtrace[1..-1])
        raise
      end
    end

    def emsg(e)
      if e.is_a?(Exception)
        "#{ e.message } (#{ e.class.name })\n#{ Array(e.backtrace).join(10.chr) }"
      else
        e.to_s
      end
    end

    # template methods
    # |
    # v
    def template(method = :tap, *args, &block)
      Template.send(method, *args, &(block || proc {}))
    end

    def render(path, context = nil)
      Template.render(path, context:)
    end

    def render_src(path, context = nil)
      Template.render_src(path, context:)
    end

    # asset expansion methods 
    # |
    # v
    EXPAND_ASSET_URL_STRATEGIES = %i[
      accurate_expand_asset_urls
      sloppy_expand_asset_urls
    ]

    def expand_asset_url_strategies
      @expand_asset_url_strategies ||= EXPAND_ASSET_URL_STRATEGIES.dup
    end

    def expand_asset_urls(html, node)
      strategies = expand_asset_url_strategies
      error = nil

      strategies.each do |strategy|
        return send(strategy, html, node)
      rescue Object => e
        error = e
        Ro.log(:error, emsg(error))
        Ro.log(:error, "failed to expand assets via #{ strategy }")
      end

      raise error
    end

    def accurate_expand_asset_urls(html, node)
      doc = Nokogiri::HTML.fragment(html)

      doc.traverse do |element|
        if element.respond_to?(:attributes)
          element.attributes.each do |attr, attribute|
            value = attribute.value
            if value =~ %r{(?:./)?assets/(.+)$}
              path = value

              if node.path_for(path).exist?
                url = node.url_for(path)
                attribute.value = url
              else
                #Ro.error!("invalid asset=`#{ path }` in node=`#{ node.path }`")
                :noop
              end
            end
          end
        end
      end

      doc.to_s.strip
    end

    def sloppy_expand_asset_urls(html, node)
      re = %r`\s*=\s*['"](?:[.]/)?(assets/[^'"\s]+)['"]`

      html.gsub(re) do |match|
        path = match[%r`assets/[^'"\s]+`]

        if node.path_for(path).exist?
          url = node.url_for(path)
          "='#{url}'"
        else
          #Ro.error!("invalid asset=`#{ path }` in node=`#{ node.path }`")
          match
        end
      end
    end

  #
    DEFAULT_IMAGE_EXTENSIONS = %i[
      webp jpg jpeg png gif tif tiff svg
    ]

    DEFAULT_IMAGE_PATTERNS = [
      /[.](#{ DEFAULT_IMAGE_EXTENSIONS.join('|') })$/i
    ]

    def image_patterns
      @image_patterns ||= DEFAULT_IMAGE_PATTERNS.dup
    end

    def image_pattern
      Regexp.union(Ro.image_patterns)
    end

    def is_image?(path)
      !!(URI.parse(path.to_s).path =~ Ro.image_pattern)
    end

    def image_info(path)
      is = ImageSize.path(path)
      format, width, height = is.format.to_s, is.width, is.height
      {format:, width:, height:}
    end

    def uuid
      SecureRandom.uuid_v7.to_s
    end
  end

  extend Methods
end
