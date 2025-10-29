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
      Ro.config.root = root
    end

    def collections
      root.collections
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
        :img_url   => ENV['RO_IMG_URL'],
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
        :img_url   => "/ro",
        :page_size => 42,
        :log       => nil,
        :debug     => nil,
        :port      => 4242,
        :md_theme  => 'github',
      })
    end

    def config
      @config ||= Config.new
    end

    # ro init
    # |
    # v
    def initialize!
      Ro.load %w[
        html.rb
        error.rb
        klass.rb
        slug.rb
        path.rb
        text.rb
        template.rb
        methods.rb
        config.rb
        core_ext/map.rb
        config_loader.rb
        config_validator.rb
        config_hierarchy.rb
        root.rb
        collection.rb
        collection/list.rb
        node.rb
        asset.rb
        migrator.rb
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
