module Ro
  class Db
    fattr :root

    def initialize(*args, &block)
      options = Map.options_for!(args)

      @root = String(args.shift || options[:root] || Ro.root)
    end

    def collections
      @collections ||= Collection::List.new

      Dir.glob(glob){|path| @collections.add(path)}

      @collections
    end

    def glob
      File.join(root, '*')
    end

    def nodes(*args, &block)
      collections.map do |collection|
        collection.nodes(*args, &block)
      end.flatten
    end
  end
end
