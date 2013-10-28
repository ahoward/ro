module Ro
  class Db
    class Collection
      class List < ::Array
        def add(path)
          name = File.basename(path.to_s)

          unless any?{|c| c.name == name }
            collection = Collection.new(path)
            push(collection)
            sort!{|a,b| a.name <=> b.name}
          end
        end
      end

      fattr :path

      def initialize(path)
        @path = Util.realpath(path)
      end

      def basename
        File.basename(@path)
      end

      def name
        basename
      end

      def dirname
        File.dirname(@path)
      end

      def glob
        File.join(@path, '*')
      end

      def nodes
        Dir.glob(glob).map do |path|
          next unless test(?d, path)
          Ro::Node.new(path)
        end
      end
    end
  end
end
