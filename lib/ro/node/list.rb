module Ro
  class Node
    class List < ::Array
      attr_accessor :root, :options, :type, :index

      def initialize(root = Ro.config.root, options = {}, &block)
        @root = Root.for(root)
        @options = Map.for(options)
        @type = @options.has_key?(:type) ? String(@options[:type]) : nil
        @index = {}

        block.call(self) if block
      end

      def nodes
        self
      end

      def load(path)
        node = Node.new(path, root: root)
        add(node)
      end

      def add(node)
        return nil if node.nil?

        if index.has_key?(node.identifier)
          false
        else
          push(node)
          index[node.identifier] = node
          node
        end
      end

      def related(*args, &block)
        related = List.new(root)

        each do |node|
          node.related(*args, &block).each do |related_node|
            related.add(related_node)
          end
        end

        related
      end

      def [](arg, *args, &block)
        case arg
        when String, Symbol
          path = [arg, args].flatten.compact.join('/')
          paths = path.to_s.scan(%r{[^/]+})

          if @type.nil?
            type = paths.shift
            list = select { |node| type == node._type }
            list.type = type

            if paths.empty?
              list
            else
              list[*paths]
            end
          else
            id = paths.shift
            id = Slug.for(id)
            node = detect { |node| id == node.id }

            if paths.empty?
              node
            else
              node[*paths]
            end
          end
        else
          super(*args, &block)
        end
      end

      def select(*args, &block)
        List.new(root) { |list| list.replace(super) }
      end

      def where(*args, &block)
        if !args.empty? && block
          raise ArgumentError

        elsif args.empty? && block
          select { |node| node.instance_eval(&block) }

        elsif !args.empty?
          ids = args.flatten.compact.uniq.map { |arg| Slug.for(arg.to_s) }
          index = ids.inject({}) { |h, id| h.update(id => id) }
          select { |node| index[node.id] }

        else
          raise ArgumentError
        end
      end

      def find(*args, &block)
        if !args.empty? && block
          raise ArgumentError
        elsif args.empty? && block
          detect { |node| node.instance_eval(&block) }

        elsif args.size == 1
          id = args.first.to_s
          detect { |node| node.id == id }

        elsif args.size > 1
          where(*args, &block)

        else
          raise ArgumentError
        end
      end

      def identifier
        [root, type].compact.join('/')
      end

      include Pagination

      def method_missing(method, *args, &block)
        Ro.log "Ro::List(#{identifier})#method_missing(#{method.inspect}, #{args.inspect})"

        if @type.nil?
          type = method.to_s
          list = self[type]
          super unless list
          list.empty? ? super : list
        else
          node = self[Slug.for(method, join: '-')] || self[Slug.for(method, join: '_')]
          node.nil? ? super : node
        end
      end

      def binding
        Kernel.binding
      end

      def _binding
        Kernel.binding
      end
    end
  end
end
