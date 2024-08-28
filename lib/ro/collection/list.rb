module Ro
  class Collection
    class List < ::Array
      include Klass

      attr_reader :root

      def initialize(root, ...)
        @root = root
        super(...)
      end

      def get(name)
        @root.get(name)
      end

      def [](index, ...)
        return get(index) if [String, Symbol].include?(index.class)
        super(index, ...)
      end
    end
  end
end
