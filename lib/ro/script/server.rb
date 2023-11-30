module Ro
  class Script::Server
    class << self
      def run!(...)
        new(...).run!
      end
    end

    def initialize(script:)
      @script = script

      @port = @script.opts.fetch(:port)
    end

    def run!
      Ro.config.set(:url, server_url)

      #build!

      threads = [watcher!, server!]

      trap('INT') do
        threads.each do |thread|
          thread.kill
        rescue StandardError
          nil
        end
        exit
      end

      sleep
    end

    def server_url
      build_directory = Ro.config.build_directory
      document_root = build_directory.dirname
      path_info = build_directory.relative_to(document_root)
      Ro.normalize_url("http://localhost:#{@port}/#{path_info}")
    end

    def build!
      system "RO_URL=#{Ro.config.url} RO_ROOT=#{Ro.config.root} ro build"
    end

    def watcher!
      Thread.new do
        Thread.current.abort_on_exception = true
        system "RO_URL=#{Ro.config.url} RO_ROOT=#{Ro.config.root} ro build --watch"
      end
    end

    def server!
      require 'webrick'

      build_directory = Ro.config.build_directory
      document_root = build_directory.dirname

      index_url = File.join(server_url, 'index.json')

      @script.say("ro.server: @ #{index_url}", color: :magenta)

      Thread.new do
        Thread.current.abort_on_exception = true

        server = WEBrick::HTTPServer.new(
          DocumentRoot: document_root,
          Port: @port
        )

        ::Kernel.at_exit { server.shutdown }

        server.start
      end
    end
  end
end
