require_relative 'ro/_lib'

Ro.load_dependencies!

module Ro
  class << Ro
    # node stuff
    # |
    # v
    def root
      Ro.config.root
    end

    def root=(root)
      Ro.config.set(:root, Root.new(root))
    end

    def collection
      root.collection
    end

    def nodes
      root.nodes
    end

    # config
    # |
    # v
    def env
      Map.for({
                root: ENV['RO_ROOT'],
                build_directory: ENV['RO_BUILD_DIRECTORY'],
                url: ENV['RO_URL'],
                page_size: ENV['RO_PAGE_SIZE'],
                log: ENV['RO_LOG'],
                debug: ENV['RO_DEBUG'],
                port: ENV['RO_PORT']
              })
    end

    def default
      Map.for({
                # url: '/ro',
                root: './public/ro',
                build_directory: './public/api',
                url: '/api',
                page_size: '10',
                log: nil,
                debug: nil,
                port: '4242'
              })
    end

    def config
      root =
        cast(:root, Ro.env.root || Ro.default.root)

      build_directory =
        cast(:path, Ro.env.build_directory || Ro.default.build_directory)

      url =
        cast(:url, (Ro.env.url || Ro.default.url))

      page_size =
        cast(:int, Ro.env.page_size || Ro.default.page_size)

      log =
        cast(:bool, (Ro.env.log || Ro.default.log))

      debug =
        cast(:bool, (Ro.env.debug || Ro.default.debug))

      port =
        cast(:int, Ro.env.port || Ro.default.port)

      @config ||= Map.for({
                            root:,
                            build_directory:,
                            url:,
                            page_size:,
                            log:,
                            debug:,
                            port:
                          })
    end

    # init
    # |
    # v
    def initialize!
      Ro.load %w[
        error.rb
        slug.rb
        path.rb
        template.rb
        methods.rb
        root.rb
        collection.rb
        node.rb
        asset.rb
      ]

      if defined?(ActiveModel)
        Ro.load %w[
          model.rb
        ]
      end

      Ro.log! if Ro.config.log
      Ro.debug! if Ro.config.debug
    end
  end
end

Ro.tap { |ro| ro.initialize! }
