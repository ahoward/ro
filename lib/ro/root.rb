module Ro
  class Root < Path
    class << Root
      def for(arg, *args, **kws, &block)
        return arg if arg.is_a?(Root) && args.empty? && kws.empty? && block.nil?

        new(arg, *args, **kws, &block)
      end

      def collections_for(root)
        root = Root.for(root)

        Collection.new(root) do |nodes_path, collection:|
          Collection.new(nodes_path) do |node_path, collection:|
            Node.new(node_path, root: root, collection: collection)
          end
        end
      end
    end

    def collections
      @collections ||= Root.collections_for(self)
    end

    def nodes(&block)
      [].tap do |accum|
        collections.each do |collection|
          collection.each do |node|
            accum.push(block ? block.call(node) : node)
          end
        end
      end
    end
  end
end
