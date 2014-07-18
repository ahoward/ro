# -*- encoding : utf-8 -*-

  require 'fileutils'
  require 'pathname'
  require 'yaml'
  require 'digest/md5'
  require 'logger'
  require 'erb'
  require 'cgi'

#
  module Ro
    Version = '1.4.6' unless defined?(Version)

    def version
      Ro::Version
    end

    def dependencies
      {
        'map'               => [ 'map'               , ' >= 6.5.1' ] ,
        'fattr'             => [ 'fattr'             , ' >= 2.2.1' ] ,
        'tilt'              => [ 'tilt'              , ' >= 1.3.1' ] ,
        'pygments'          => [ 'pygments.rb'       , ' >= 0.5.0' ] ,
        'coerce'            => [ 'coerce'            , ' >= 0.0.4' ] ,
        'stringex'          => [ 'stringex'          , ' >= 2.1.0' ] ,
        'systemu'           => [ 'systemu'           , ' >= 2.5.2' ] ,
        'nokogiri'          => [ 'nokogiri'          , ' >= 1.6.1' ] , 
        'main'              => [ 'main'              , ' >= 5.2.0' ] , 
      }
    end

    def libdir(*args, &block)
      @libdir ||= File.expand_path(__FILE__).sub(/\.rb$/,'')
      args.empty? ? @libdir : File.join(@libdir, *args)
    ensure
      if block
        begin
          $LOAD_PATH.unshift(@libdir)
          block.call()
        ensure
          $LOAD_PATH.shift()
        end
      end
    end

    def load(*libs)
      libs = libs.join(' ').scan(/[^\s+]+/)
      Ro.libdir{ libs.each{|lib| Kernel.load(lib) } }
    end

    extend(Ro)
  end

#
  begin
    require 'rubygems'
  rescue LoadError
    nil
  end

  if defined?(gem)
    Ro.dependencies.each do |lib, dependency|
      gem(*dependency)
      require(lib)
    end
  end

  %w[
    fileutils
    yaml
  ].each do |lib|
    require lib
  end

#

  module Ro
    def Ro.default_root
      [ ENV['RO_ROOT'], "./public/ro", "./source/ro" ].compact.detect{|d| test(?d, d)} || "./ro"
    end

    def Ro.root=(root)
      @root = Root.new(root.to_s)
    end

    def Ro.root(*args)
      Ro.root = args.first unless args.empty?
      @root ||= Root.new(Ro.default_root)
    end

    def Ro.git
      root.git
    end

    def Ro.patch(*args, &block)
      git.patch(*args, &block)
    end

    Fattr(:cache){
      Cache.new
    }

    Fattr(:logger){
      nil
    }

    Fattr(:route){
      '/ro'
    }

    Fattr(:asset_host){
      nil
    }

    def Ro.nodes(*args, &block)
      root.nodes(*args, &block)
    end

    def Ro.relative_path(path, *args)
      options = Map.options_for!(args)
      path = File.expand_path(String(path))
      relative = File.expand_path(String(args.shift || options[:relative] || options[:to]) || options[:from])
      Pathname.new(path).relative_path_from(Pathname.new(relative)).to_s
    end

    def Ro.realpath(path)
      Pathname.new(path.to_s).realpath
    end

    def Ro.md5(string)
      Digest::MD5.hexdigest(string)
    end

    def Ro.debug!
      @logger ||= (
        logger = ::Logger.new(STDERR)
        logger.level = ::Logger::DEBUG
        logger
      )
    end

    def Ro.log(*args, &block)
      return if @logger.nil?

      level =
        if args.size == 1
          :debug
        else
          args.shift
        end

      @logger.send(level, *args, &block)
    end

    def Ro.slug_for(*args, &block)
      options = Map.options_for!(args)
      unless options.has_key?(:join)
        options[:join] = '-'
      end
      args.push(options)
      Slug.for(*args, &block)
    end

    def Ro.name_for(*args, &block)
      options = Map.options_for!(args)
      unless options.has_key?(:join)
        options[:join] = '_'
      end
      args.push(options)
      Slug.for(*args, &block)
    end

    def Ro.erb(content, node = nil)
      binding =
        case node
          when Binding
            node
          when Node
            node._binding
          when nil
            nil
          else
            instance_eval{ Kernel.binding }
        end

      ERB.new(content.to_s).result(binding)
    end

    def Ro.render(*args, &block)
      Template.render(*args, &block)
    end

    def Ro.render_source(*args, &block)
      Template.render_source(*args, &block)
    end

    def Ro.expand_asset_urls(html, node)
      begin
        accurate_expand_asset_urls(html, node)
      rescue Object
        sloppy_expand_asset_urls(html, node)
      end
    end

    def Ro.accurate_expand_asset_urls(html, node)
      doc = Nokogiri::HTML.fragment(html)

      doc.traverse do |element|
        if element.respond_to?(:attributes)
          element.attributes.each do |attr, attribute|
            value = attribute.value
            if value =~ %r{(?:./)?assets/(.+)$}
              begin
                base, ext = $1.split('.', 2)
                url = node.url_for(base)
                attribute.value = url
              rescue Object
                next
              end
            end
          end
        end
      end

      doc.to_s.strip
    end

    def Ro.sloppy_expand_asset_urls(html, node)
      html.to_s.gsub(%r{['"]assets/([^'"]+)['"]}) do |match|
        base, ext = $1.split('.', 2)

        begin
          node.url_for(base).inspect
        rescue Object
          match
        end
      end
    end

    def Ro.paths_for(*args)
      path = args.flatten.compact.join('/')
      path.gsub!(%r|[.]+/|, '/')
      path.squeeze!('/')
      path.sub!(%r|^/|, '')
      path.sub!(%r|/$|, '')
      paths = path.split('/')
    end

    def Ro.absolute_path_for(*args)
      path = ('/' + paths_for(*args).join('/')).squeeze('/')
      path unless path.empty?
    end

    def Ro.relative_path_for(*args)
      path = absolute_path_for(*args).sub(%r{^/+}, '')
      path unless path.empty?
    end
      
    def Ro.normalize_path(arg, *args)
      absolute_path_for(arg, *args)
    end

    def Ro.query_string_for(hash, options = {})
      options = Map.for(options)
      escape = options.has_key?(:escape) ? options[:escape] : true
      pairs = [] 
      esc = escape ? proc{|v| CGI.escape(v.to_s)} : proc{|v| v.to_s}
      hash.each do |key, values|
        key = key.to_s
        values = [values].flatten
        values.each do |value|
          value = value.to_s
          if value.empty?
            pairs << [ esc[key] ]
          else
            pairs << [ esc[key], esc[value] ].join('=')
          end
        end
      end
      pairs.replace pairs.sort_by{|pair| pair.size}
      pairs.join('&')
    end

    def Ro.realpath(path)
      begin
        Pathname.new(path.to_s).expand_path.realpath.to_s
      rescue Object
        File.expand_path(path.to_s)
      end
    end

  end

#
  module Kernel
    def ro(*args, &block)
      Ro.nodes(*args, &block)
    end
  end

#
  Ro.load %w[

    initializers/tilt.rb
    initializers/env.rb
                
    slug.rb
    blankslate.rb

    root.rb
    lock.rb
    git.rb
    pagination.rb

    cache.rb

    template.rb
    node.rb
    node/list.rb

  ]
