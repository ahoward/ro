module Ro
  VERSION = '4.2.0' unless defined?(VERSION)

  class << self
    def version
      VERSION
    end

    def summary
      <<~____
        keep *all* your content in github, as god intended.
      ____
    end

    def description
      <<~____
        the worlds tiniest, bestest, most minmialist headless cms - powered by github

        ro is a minimalist toolkit for managing heterogeneous collections of rich web
        content on github, and providing both programatic and api access to it with zero
        heavy lifting
      ____
    end

    def libs
      %w[
        fileutils pathname yaml json logger erb cgi rexml time date
      ]
    end

    def dependencies
      {
        'map' =>
          ['map', '~> 6.6', '>= 6.6.0'],

        'kramdown' =>
          ['kramdown', '~> 2.4', ' >= 2.4.0'],

        'kramdown-parser-gfm' =>
          ['kramdown-parser-gfm', '~> 1.1', ' >= 1.1.0'],

        'rouge' =>
          ['rouge', '~> 4.1', ' >= 4.1.1'],

        'ak47' =>
          ['ak47', '~> 0.2'],

        'webrick' =>
          ['webrick', '~> 1.8.1'],
      }
    end

    def libdir(*args, &block)
      @libdir ||= File.dirname(File.expand_path(__FILE__))
      args.empty? ? @libdir : File.join(@libdir, *args)
    ensure
      if block
        begin
          $LOAD_PATH.unshift(@libdir)
          block.call
        ensure
          $LOAD_PATH.shift
        end
      end
    end

    def load(*libs)
      libs = libs.join(' ').scan(/[^\s+]+/)
      libdir { libs.each { |lib| Kernel.load(lib) } }
    end

    def load_dependencies!
      libs.each do |lib|
        require lib
      end

      begin
        require 'rubygems'
      rescue LoadError
        nil
      end

      has_rubygems = defined?(gem)

      dependencies.each do |lib, dependency|
        gem(*dependency) if has_rubygems
        require(lib)
      end
    end
  end
end
