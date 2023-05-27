module Ro
  VERSION = '2.0.0' unless defined?(VERSION)

  class << self
    def version
      VERSION
    end

    def libs
      %w[
        fileutils pathname yaml json digest/md5 logger erb cgi rexml
      ]
    end

    def dependencies
      {
        'map' => ['map', '~> 6.6', '>= 6.6.0'],
        'fattr' => ['fattr', '~> 2.4', ' >= 2.4.0'],
        'tilt' => ['tilt', '~> 2.1', ' >= 2.1.0'],
        'kramdown' => ['kramdown', '~> 2.4', ' >= 2.4.0'],
        'rouge' => ['rouge', '~> 4.1', ' >= 4.1.1'],
        'main' => ['main', '~> 6.3', ' >= 6.3.0'],
        'listen' => ['listen', '~> 3.8', ' >= 3.8.0']
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
