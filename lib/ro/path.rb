require 'pathname'

module Ro
  class Path < ::String
    def self.components_for(*args)
      path = args.flatten.compact.join('/').strip
      absolute = path.start_with?('/')
      paths = path.scan(%r{[^/]+})
      absolute ? ['/'] + paths : paths
    end

    def self.normalized_string(*args)
      components_for(*args).join('/').squeeze('/')
    end

    def self.normalize(...)
      new(...)
    end

    def self.absolute(...)
      new(...).absolute!
    end

    def self.relative(...)
      new(...).relative!
    end

    def self.for(arg, *args, **kws, &block)
      return arg if arg.is_a?(Path) && args.empty? && kws.empty? && block.nil?

      new(arg, *args, **kws, &block)
    end

    def initialize(arg, *args)
      super Path.normalized_string(arg, *args)
    end

    def absolute!
      relative!
      replace('/' + self)
      self
    end

    def relative!
      gsub! %r{^/+}, ''
      self
    end

    def key
      Path.components_for(self)
    end

    def parts
      key
    end

    def pathname
      Pathname.new(self)
    end

    def name
      pathname
    end

    def pn
      pathname
    end

    public_pathname_methods = Pathname.instance_methods(false)
    all_string_methods = String.instance_methods
    real_string_methods = all_string_methods.select { |method| method.to_s !~ /(^object_id$)|(^_)/ }

    safe_to_define = public_pathname_methods - real_string_methods
    safe_to_redefine = real_string_methods

    safe_to_define.each do |method|
      # p define: method
      class_eval <<-____, __FILE__, __LINE__ + 1
        def self.#{method}(arg, *args, &block)
          Path.for(arg).public_send('#{method}', *args, &block)
        end
      ____

      class_eval <<-____, __FILE__, __LINE__ + 1
        def #{method}(...)
          result = pathname.public_send('#{method}', ...)

          if result.is_a?(Pathname)
            Path.new(result.to_s)
          else
            result
          end
        end
      ____
    end

    safe_to_redefine.each do |method|
      # p redefine: method
      class_eval <<-____, __FILE__, __LINE__ + 1
        def #{method}(...)
          result = super(...)

          if result.is_a?(String)
            Path.new(result.to_s)
          else
            result
          end
        end
      ____
    end

    def relative_to(other)
      relative_path_from(Path.for(other))
    end

    def self.method_missing(method, ...)
      super unless pathname.respond_to?(method)

      result = pathname.public_send(method, ...)

      if result.is_a?(Pathname)
        Path.new(result.to_s)
      else
        result
      end
    end
  end
end
