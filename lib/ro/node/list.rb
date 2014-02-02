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

      def [](*args, &block)
        key = args.first

        case key
          when String, Symbol
            if @type.nil?
              type = key.to_s
              list = select{|node| type == node._type}
              list.type = type
              list
            else
              id = Slug.for(key.to_s)
              detect{|node| id == node.id}
            end
          else
            super(*args, &block)
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
            ids = args.flatten.compact.uniq.map{|arg| Slug.for(arg.to_s)}
            index = ids.inject(Hash.new){|h,id| h.update(id => id)}
            select{|node| index[node.id]}

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
            id = args.first.to_s
            detect{|node| node.id == id}

          when args.size > 1
            where(*args, &block)

          else
            raise ArgumentError.new
        end
      end

      def identifier
        [root, type].compact.join('/')
      end

      def paginate(*args)
        options = Map.options_for!(args)

        ensure_pagination_state!

        page = Integer(args.shift || options[:page] || @page)
        per = Integer(args.shift || options[:per] || options[:size] || @per)

        @page = [page.abs, 1].max
        @per = [per.abs, 1].max

        offset = (@page - 1) * @per
        length = @per 

        replace(self.slice(offset, length))

        self
      end

      def page(*args)
        ensure_pagination_state!

        if args.empty?
          return @page
        else
          options = Map.options_for!(args)
          page = args.shift || options[:page]
          options[:page] = page
          paginate(options)
        end
      end

      alias_method(:current_page, :page)

      def per(*args)
        ensure_pagination_state!

        if args.empty?
          return @per
        else
          options = Map.options_for!(args)
          per = args.shift || options[:per]
          options[:per] = per
          paginate(options)
        end
      end

      def num_pages
        (size.to_f / per).ceil
      end

      def total_pages
        num_pages
      end

      def ensure_pagination_state!
        unless defined?(@page)
          @page = 1
        end
        unless defined?(@per)
          @per = size
        end
        [@page, @per]
      end


      def method_missing(method, *args, &block)
        Ro.log "Ro::List(#{ identifier })#method_missing(#{ method.inspect }, #{ args.inspect })"

        if @type.nil?
          type = method.to_s
          list = self[type]
          super unless list
          list.empty? ? super : list
        else
          node = self[Slug.for(method, :join => '-')] || self[Slug.for(method, :join => '_')]
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
