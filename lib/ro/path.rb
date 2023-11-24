require 'pathname'

module Ro
  class Path < ::String
    @@DEFAULT_IMAGE_PATTERN = /[.](webp|jpg|jpeg|png|gif|tif|tiff|svg)$/i

    class << Path
      def for(arg, *args, **kws, &block)
        return arg if arg.is_a?(Path) && args.empty? && kws.empty? && block.nil?

        new(arg, *args, **kws, &block)
      end

      def clean(arg, *args)
        Pathname.new([arg, *args].join('/')).cleanpath.to_s
      end

      def expand(arg, *args)
        new(Pathname.new(clean(arg, *args).expand_path))
      end

      def absolute(...)
        new(...).absolute
      end

      def absolute?(arg, *args)
        Path.for(arg, *args).absolute?
      end

      def relative(...)
        new(...).relative
      end

      def relative?(arg, *args)
        Path.for(arg, *args).relative?
      end

      def image_patterns
        [@@DEFAULT_IMAGE_PATTERN]
      end
    end

    def initialize(arg, *args)
      super Path.clean(arg, *args)
    end

    def pn
      Pathname.new(self)
    end

    {
      'exist?' => 'exist?',
      'file?' => 'file?',
      'directory?' => 'directory?',
      'absolute?' => 'directory?',
      'relative?' => 'relative?',
      'expand' => 'expand_path',
      'clean' => 'cleanpath'
    }.each do |src, dst|
      class_eval <<-____, __FILE__, __LINE__ + 1
        def #{src}(...)
          result = pn.#{dst}(...)
          result.is_a?(Pathname) ? Path.for(result) : result
        end
      ____
    end

    def image?
      self.class.image_patterns.any? { |pattern| file? && pattern === basename }
    end

    def absolute
      Path.new('/' + self)
    end

    def relative
      Path.new(absolute.gsub(%r{^/+}, ''))
    end

    def parts
      parts = scan(%r{[^/]+})

      if absolute?
        head, *tail = parts
        head = ["/#{head}"]
        head + tail
      else
        parts
      end
    end

    def key
      parts
    end

    def relative_to(other)
      a = Pathname.new(self).expand_path
      b = Pathname.new(other).expand_path
      Path.for(a.relative_path_from(b))
    end

    def relative_from(...)
      relative_to(...)
    end

    def relative_to!(other)
      a = Pathname.new(self).realpath
      b = Pathname.new(other).realpath
      Path.for(a.relative_path_from(b))
    end

    def glob(arg = '**/**', *args, **kws, &block)
      glob = Path.for(self, arg, *args, **kws)

      [].tap do |accum|
        Dir.glob(glob) do |entry|
          path = Path.new(entry)
          accum.push(block ? block.call(path) : path)
        end
      end
    end

    def select(&block)
      glob.select(&block)
    end

    def detect(&block)
      glob.detect(&block)
    end

    def parent
      Path.for(File.dirname(self))
    end
    alias dirname parent

    def basename
      Path.for(File.basename(self))
    end

    def base
      base, ext = basename.split('.', 2)
      base
    end

    def extension
      base, ext = basename.split('.', 2)
      ext
    end
    alias ext extension

    def join(arg, *args)
      Path.for(self, Path.clean(arg, *args))
    end

    def binwrite(data)
      FileUtils.mkdir_p(dirname)
      IO.binwrite(self, data)
    end
  end
end
