module Co
  class Node
    class List < ::Array
      def method_missing(method, *args, &block)
      end

      def [](*args)
        case args.first
          when Symbol, String
          else
            super
        end
      end
    end
  end
end
