module Ro
  class Asset < ::String
    include Klass

    attr_reader :path, :node, :relative_path, :name, :url, :cdn_url

    def initialize(arg, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}

      @path = Path.for(arg, *args)

      @node = options.fetch(:node) { Node.for(@path.split('/assets/').first) }

      @relative_path = @path.relative_to(@node.path)

      @name = @relative_path

      @url = @node.url_for(@relative_path)

      @cdn_url = @node.cdn_url_for(@relative_path)

      super(@path)
    end

    def is_img?
      @path.file? && Ro.is_image?(@path.basename)
    end

    alias is_img is_img?

    def img
      return unless is_img?
      Ro.image_info(path.to_s)
    end

    def is_src?
      key = relative_path.parts
      subdir = key.size > 2 ? key[1] : nil
      !!(subdir == 'src')
    end

    alias is_src is_src?

    def src
      return unless is_src?
      Ro.render_src(path, node)
    end

    def stat
      @path.stat.size
    end

    def size
      stat.size
    end
  end
end
