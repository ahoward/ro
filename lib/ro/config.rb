module Ro
  class Config < ::Map
    def Config.defaults
      {
        :root =>
          (Ro.env.root || Ro.defaults.root),

        :build =>
          (Ro.env.build || Ro.defaults.build),

        :url =>
          (Ro.env.url || Ro.defaults.url),

        :page_size =>
          (Ro.env.page_size || Ro.defaults.page_size),

        :log =>
          (Ro.env.log || Ro.defaults.log),

        :debug =>
          (Ro.env.debug || Ro.defaults.debug),

        :port =>
          (Ro.env.port || Ro.defaults.port),

        :md_theme =>
          (Ro.env.md_theme || Ro.defaults.md_theme),
      }
    end

    def initialize(*args, **kws)
      configure!(Config.defaults)

      args.each do |arg|
        configure!(arg) if arg.is_a?(Hash)
      end

      configure!(kws)
    end

    def configure!(hash)
      hash.each do |key, value|
        send("#{ key }=", value)
      end
    end

    {
      :root      => :root,
      :build     => :path,
      :url       => :url,
      :page_size => :int,
      :log       => :bool,
      :debug     => :bool,
      :port      => :int,
      :md_theme  => :string,
    }.each do |attribute, cast|
      class_eval <<-____, __FILE__, __LINE__ + 1
        def #{ attribute }
          get :#{ attribute }
        end

        def #{ attribute }=(value)
          set :#{ attribute }, Ro.cast(:#{ cast }, value)
        end
      ____
    end
  end
end
