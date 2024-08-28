require_relative 'ro/_lib'

Ro.load_dependencies!

module Ro
  class << Ro
    # top-level 
    # |
    # v
    def root
      Ro.config.root
    end

    def root=(root)
      Ro.config.set(:root, Root.for(root))
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
        :root      => ENV['RO_ROOT'],
        :build     => ENV['RO_BUILD'],
        :url       => ENV['RO_URL'],
        :page_size => ENV['RO_PAGE_SIZE'],
        :log       => ENV['RO_LOG'],
        :debug     => ENV['RO_DEBUG'],
        :port      => ENV['RO_PORT'],
        :md_theme  => ENV['RO_MD_THEME'],
      })
    end

    def defaults
      Map.for({
        :root      => './public/ro',
        :build     => './public/api/ro',
        :url       => "/ro",
        :page_size => 42,
        :log       => nil,
        :debug     => nil,
        :port      => 4242,
        :md_theme  => 'github',
      })
    end

    def config
      root =
        cast(:root, (Ro.env.root || Ro.defaults.root))

      build =
        cast(:path, (Ro.env.build || Ro.defaults.build))

      url =
        cast(:url, (Ro.env.url || Ro.defaults.url))

      page_size =
        cast(:int, (Ro.env.page_size || Ro.defaults.page_size))

      log =
        cast(:bool, (Ro.env.log || Ro.defaults.log))

      debug =
        cast(:bool, (Ro.env.debug || Ro.defaults.debug))

      port =
        cast(:int, (Ro.env.port || Ro.defaults.port))

      md_theme =
        cast(:string, (Ro.env.md_theme || Ro.defaults.md_theme))

      Map.for({
        root:,
        build:,
        url:,
        page_size:,
        log:,
        debug:,
        port:,
        md_theme:,
      })
    end

    # ro init
    # |
    # v
    def initialize!
      Ro.load %w[
        error.rb
        promise.rb
        klass.rb
        slug.rb
        path.rb
        template.rb
        methods.rb
        root.rb
        collection.rb
        collection/list.rb
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

Ro.initialize!
