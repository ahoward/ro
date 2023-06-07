module Ro
  class Node
    class Asset < ::String
      fattr(:node)
      fattr(:path)
      fattr(:relative_path)
      fattr(:url)

      def initialize(node, path)
        @node = node
        @path = Ro.realpath(path)
        @relative_path = Ro.path_for(@path.to_s.gsub(/^#{Regexp.escape(@node.asset_dir)}/, 'assets'))
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
    end
  end
end
