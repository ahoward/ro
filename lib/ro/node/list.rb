module Ro
  class Node
    class List < ::Array
      fattr :root
      fattr :type
      fattr :index

      def initialize(*args, &block)
        options = Map.options_for!(args)

        root = args.shift || options[:root]
        type = args.shift || options[:type]

        @root = Root.new(root)
        @type = type.nil? ? nil : String(type)
        @index = {}

        block.call(self) if block
      end

      def nodes
        self
      end

      def load(path)
        add( node = Node.new(path) )
      end

      def add(node)
        return nil if node.nil?

        unless index.has_key?(node.identifier)
          push(node)
          index[node.identifier] = node
          node
        else
          false
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

      def [](key)
        if @type.nil?
          type = key.to_s
          list = select{|node| type == node.type}
          list.type = type
          list
        else
          name = key.to_s
          detect{|node| name == node.name}
        end
      end

      def select(*args, &block)
        List.new(root){|list| list.replace(super)}
      end

      def where(*args, &block)
        case
          when !args.empty? && block
            raise ArgumentError.new

          when args.empty? && block
            select{|node| node.instance_eval(&block)}

          when !args.empty?
            names = args.flatten.compact.uniq.map{|arg| arg.to_s}
            index = names.inject(Hash.new){|h,name| h.update(name => name)}
            select{|node| index[node.name]}

          else
            raise ArgumentError.new
        end
      end

      def find(*args, &block)
        case
          when !args.empty? && block
            raise ArgumentError.new
          when args.empty? && block
            detect{|node| node.instance_eval(&block)}

          when args.size == 1
            name = args.first.to_s
            detect{|node| node.name == name}

          when args.size > 1
            where(*args, &block)

          else
            raise ArgumentError.new
        end
      end

      def identifier
        [root, type].compact.join('/')
      end

      def method_missing(method, *args, &block)
        Ro.log "Ro::List(#{ identifier })#method_missing(#{ method.inspect }, #{ args.inspect })"

        if @type.nil?
          type = method.to_s
          list = self[type]
          super unless list
          list.empty? ? super : list
        else
          name = Ro.slug_for(method)
          node = self[name]
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
