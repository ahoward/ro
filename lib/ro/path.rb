require 'pathname'

module Ro
  class Path < ::String
    include Klass

    class << Path
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
    end

    def initialize(arg, *args)
      super Path.clean(arg, *args)
    end

    def pn
      Pathname.new(self)
    end

    def klass
      self.class
    end

    {
      'exist?'     => 'exist?',
      'file?'      => 'file?',
      'directory?' => 'directory?',
      'absolute?'  => 'directory?',
      'relative?'  => 'relative?',
      'expand'     => 'expand_path',
      'clean'      => 'cleanpath'
    }.each do |path_method, pathname_method|
      class_eval <<-____, __FILE__, __LINE__ + 1

        def #{ path_method }(...)
          result = pn.#{ pathname_method }(...)

          result.is_a?(Pathname) ? klass.for(result) : result
        end

      ____
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

      accum = []

      Dir.glob(glob) do |entry|
        path = Path.new(entry)
        block ? block.call(path) : accum.push(path)
      end

      accum
    end

    def files(arg = '**/**', *args, **kws, &block)
      glob = Path.for(self, arg, *args, **kws)

      accum = []

      Dir.glob(glob) do |entry|
        next unless test(?f, entry)
        path = Path.new(entry)
        block ? block.call(path) : accum.push(path)
      end

      accum
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
    alias name basename

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

    def sibling?(other)
      expand.dirname == Path.for(other).expand.dirname
    end

    def child?(other)
      parent = expand
      child = Path.for(other).expand
      (parent.size < child.size && child.start_with?(parent))
    end

    def parent?(other)
      child = expand
      parent = Path.for(other).expand
      (parent.size < child.size && child.start_with?(parent))
    end

    def file?
      test(?f, self)
    end

    def directory?
      test(?d, self)
    end

    def subdirectories(&block)
      accum = []

      glob('*') do |entry|
        next unless entry.directory?
        block ? block.call(entry) : accum.push(entry)
      end

      block ? self : accum
    end
    alias subdirs subdirectories 

    def subdirectory_for(subdirectory)
      join(Path.relative(subdirectory))
    end
    alias subdir_for subdirectory_for

    def subdirectory?(subdirectory)
      subdirectory = join(Path.relative(subdirectory))
      subdirectory.exist?
    end
    alias subdir? subdirectory?
  end
end
