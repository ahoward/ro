module Ro
  class Slug < ::String
    @@JOIN = '-'

    class << Slug
      def for(arg, *args, &block)
        return arg if arg.is_a?(Slug) && args.empty? && block.nil?
        new(arg, *args, &block)
      end
    end

    def initialize(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}

      join = (options[:join] || options['join'] || @@JOIN).to_s

      string = args.flatten.compact.join(join)
      words = string.to_s.scan(%r{[/\w]+})
      words.map! { |word| word.gsub(/[_-]/, join) }
      words.map! { |word| word.gsub %r{[^/0-9a-zA-Z_-]}, '' }
      words.delete_if { |word| word.nil? or word.strip.empty? }

      slug = words.join(join).downcase.gsub('/', (join * 2))

      super(slug)
    end
  end
end
