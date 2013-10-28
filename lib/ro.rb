# -*- encoding : utf-8 -*-

  require 'fileutils'
  require 'pathname'
  require 'yaml'
  require 'digest/md5'
  require 'logger'
  require 'erb'

#
  module Ro
    Version = '1.0.0' unless defined?(Version)

    def version
      Ro::Version
    end

    def dependencies
      {
        'map'               => [ 'map'               , ' >= 6.5.1' ] ,
        'fattr'             => [ 'fattr'             , ' >= 2.2.1' ] ,
        'tilt'              => [ 'tilt'              , ' >= 1.4.1' ] ,
        'pygments'          => [ 'pygments.rb'       , ' >= 0.5.0' ] ,
        'coerce'            => [ 'coerce'            , ' >= 0.0.4' ] ,
        'stringex'          => [ 'stringex'          , ' >= 2.1.0' ] ,
      # 'rails'             => [ 'rails'             , ' >= 3.1'   ] ,
      # 'tagz'              => [ 'tagz'              , ' >= 9.9.2' ] ,
      # 'multi_json'        => [ 'multi_json'        , ' >= 1.0.3' ] ,
      # 'uuidtools'         => [ 'uuidtools'         , ' >= 2.1.2' ] ,
      # 'wrap'              => [ 'wrap'              , ' >= 1.5.0' ] ,
      # 'rails_current'     => [ 'rails_current'     , ' >= 1.8.0' ] ,
      # 'rails_errors2html' => [ 'rails_errors2html' , ' >= 1.3.0' ] ,
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
    Fattr(:root){
      Root.new(
        case
          when defined?(Rails.root)
            Rails.root.to_s

          when defined?(Middleman::Application)
            Middleman::Application.server.root.to_s

          else
            "./ro"
        end
      )
    }

    Fattr(:cache){
      Cache.new
    }

    Fattr(:logger){
      nil
    }

    def Ro.nodes(*args, &block)
      root.nodes(*args, &block)
    end

    def Ro.relative_path(path, *args)
      options = Map.options_for!(args)
      path = File.expand_path(String(path))
      relative = File.expand_path(String(args.shift || options[:relative] || options[:to]))
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
      options[:join] = '-'
      args.push(options)
      Slug.for(*args, &block)
    end

    def Ro.name_for(*args, &block)
      options = Map.options_for!(args)
      options[:join] = '_'
      args.push(options)
      Slug.for(*args, &block)
    end

    def Ro.erb(content, node = nil)
      binding =
        case node
          when Binding
            node
          when Node
            node.binding
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
    util.rb

    root.rb

    cache.rb

    template.rb
    node.rb
    node/list.rb

  ]
