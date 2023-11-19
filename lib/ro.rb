require_relative 'ro/_lib'

Ro.load_dependencies!

module Kernel
  def ro(*args, &block)
    Ro.collection(*args, &block)
  end
end

module Ro
  class << Ro
    # node stuff
    # |
    # v
    def root(*args, &block)
      Ro::Root.new(*args, &block)
    end

    def root=(root)
      ENV['RO_ROOT'] = root.to_s
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
    def default
      Map.for({
                url: '/ro',
                path: './ro:./public/ro',
                root: nil,
                log: nil,
                debug: nil,
                build_directory: './public/api/ro',
                page_size: '10',
              })
    end

    def env
      Map.for({
                url: ENV['RO_URL'],
                path: ENV['RO_PATH'],
                root: ENV['RO_ROOT'],
                log: ENV['RO_LOG'],
                debug: ENV['RO_DEBUG'],
                build_directory: ENV['RO_BUILD_DIRECTORY'],
                page_size: ENV['RO_PAGE_SIZE'],
              })
    end

    def config
      root = cast(:string_or_nil, Ro.env.root || Ro.default.root)
      url = cast(:url, (Ro.env.url || Ro.default.url))
      path = cast(:array, (Ro.env.path || Ro.default.path))
      debug = cast(:bool, (Ro.env.debug || Ro.default.debug))
      log = cast(:bool, (Ro.env.log || Ro.default.log))
      build_directory = cast(:string_or_nil, Ro.env.build_directory || Ro.default.build_directory)
      page_size = cast(:int, Ro.env.page_size || Ro.default.page_size)

      Map.for({
                root: root,
                url: url,
                path: path,
                log: log,
                debug: debug,
                build_directory: build_directory,
                page_size: page_size,
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
        model.rb
        pagination.rb
      ]

      Ro.log! if Ro.config.log
      Ro.debug! if Ro.config.debug
    end
  end
end

Ro.tap { |ro| ro.initialize! }
