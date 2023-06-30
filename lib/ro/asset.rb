module Ro
  class Asset < ::String
    attr_reader :node, :path, :relative_path, :url

    def initialize(node, path)
      @node = node
      @path = Path.for(path)
      @relative_path = @path.relative_to(@node.path)
      @url = @node.url_for(@relative_path)
      super(@url)
    end

    def basename
      File.basename(path)
    end

    def extension
      base, ext = basename.split('.', 2)
      ext
    end
    alias ext extension

    IMAGE_RE = /[.](jpg|jpeg|png|gif|tif|tiff|svg)$/i

    def image?
      !!(basename =~ IMAGE_RE)
    end

    def src
      key = relative_path.parts
      subdir = key.size > 2 ? key[1] : nil
      is_src = subdir == 'src'

      return unless is_src

      Ro.render_src(path, node)
    end
  end
end
