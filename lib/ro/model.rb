begin
  require 'active_model'
  require 'active_support'
  require 'active_support/core_ext/string/inflections'
rescue LoadError => e
  abort "you need to add the 'active_model' and 'active_support' gems to use Ro::Model"
end

require_relative '../ro' unless defined?(Ro)

module Ro
  class Model
    require_relative 'pagination'

    extend ActiveModel::Naming
    extend ActiveModel::Translation
    include ActiveModel::Validations
    include ActiveModel::Conversion

    class << Model
      def default_collection_name
        name.to_s.split(/::/).last.underscore.pluralize
      end

      def collection_name(collection_name = nil)
        @collection_name = collection_name.to_s if collection_name

        @collection_name || default_collection_name
      end

      def collection
        root.collections[collection_name]
      end

      def nodes
        collection.to_a
      end

      def all
        models_for(nodes)
      end

      def select(*args, &block)
        all.select(*args, &block)
      end

      def detect(*args, &block)
        all.detect(*args, &block)
      end

      def count(*args, &block)
        if args.empty? and block.nil?
          all.size
        else
          where(*args, &block).size
        end
      end

      def where(*_args, &block)
        all.select do |model|
          !!model.instance_eval(&block)
        end
      end

      def first
        all.first
      end

      def last
        all.last
      end

      def find(id)
        slug = Slug.for(id)
        all.detect { |model| Slug.for(model.id) == slug }
      end

      def [](id)
        find(id)
      end

      def method_missing(method, *args, &block)
        id = method
        model = find(id)
        return model if model

        super
      end

      def models_for(result)
        case result
        when Array
          List.for(Array(result).flatten.compact.map { |element| new(element) })
        else
          new(result)
        end
      end

      def paginate(*args, &block)
        all.paginate(*args, &block)
      end
    end

    class List < ::Array
      include Pagination

      class << List
        def for(*args, &block)
          new(*args, &block)
        end
      end

      def select(*args, &block)
        List.for super
      end

      def detect(*args, &block)
        super
      end
    end

    def List(*args, &block)
      List.new(*args, &block)
    end

    attr_accessor(:node)

    def initialize(*args)
      attributes = Map.options_for!(args)

      node = args.detect { |arg| arg.is_a?(Node) }
      model = args.detect { |arg| arg.is_a?(Model) }

      node = model.node if node.nil? and !model.nil?

      if node
        @node = node
      else
        path = File.join(prefix, ':new')
        node = Node.new(path)
        @node = node
      end
    end

    def attributes
      @node.attributes
    end

    def persisted?
      true
    end

    def prefix
      self.class.prefix
    end

    def method_missing(method, *args, &block)
      node.send(method, *args, &block)
    end

    def respond_to?(method, *args, &block)
      super || node.respond_to?(method)
    end
  end
end
