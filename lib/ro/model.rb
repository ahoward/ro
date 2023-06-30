begin
  require 'active_model'
  require 'active_support'
  require 'active_support/core_ext/string/inflections'
rescue LoadError => e
  abort "you need to add the 'active_model' and 'active_support' gems to use Ro::Model"
end

module Ro
  class Model
    extend ActiveModel::Naming
    extend ActiveModel::Translation
    include ActiveModel::Validations
    include ActiveModel::Conversion

    Fattr(:collection) { default_collection_name }
    Fattr(:default_collection_name) { name.to_s.split(/::/).last.underscore.pluralize }
    Fattr(:root) { Ro.root }
    Fattr(:prefix) { File.join(root, collection) }

    def self.nodes(*_args)
      root.nodes.send(collection)
    end

    def self.all(*_args)
      models_for(nodes)
    end

    def self.select(*args, &block)
      all.select(*args, &block)
    end

    def self.detect(*args, &block)
      all.detect(*args, &block)
    end

    def self.count(*args, &block)
      if args.empty? and block.nil?
        all.size
      else
        where(*args, &block).size
      end
    end

    def self.where(*_args, &block)
      all.select do |model|
        !!model.instance_eval(&block)
      end
    end

    def self.first
      all.first
    end

    def self.last
      all.last
    end

    def self.find(id)
      # re = /#{id.to_s.gsub(\/[-_]\/, '[-_]')}/i
      # all.detect { |model| model.id.to_s == id.to_s }
      # re = /#{id.to_s.gsub(\/[-_]\/, '[-_]')}/i
      slug = Slug.for(id)
      all.detect { |model| Slug.for(model.id) == slug }
    end

    def self.[](id)
      find(id)
    end

    def self.method_missing(method, *args, &block)
      id = method
      model = find(id)
      return model if model

      super
    end

    def self.models_for(result)
      case result
      when Array
        List.for(Array(result).flatten.compact.map { |element| new(element) })
      else
        new(result)
      end
    end

    def self.paginate(*args, &block)
      all.paginate(*args, &block)
    end

    class List < ::Array
      include Pagination

      def self.for(*args, &block)
        new(*args, &block)
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

    def directory
      File.join(prefix, id)
    end

    def method_missing(method, *args, &block)
      node.send(method, *args, &block)
    end

    def respond_to?(method, *args, &block)
      super || node.respond_to?(method)
    end
  end
end

if __FILE__ == $0

  ENV['RO_ROOT'] = '../sample_ro_data'

  class Person < Ro::Model
    # field(:first_name, :type => :string)
  end

  p Person.collection
  p Person.all
  p Person.find(:ara).attributes
  ara = Person.find(:ara)

  p ara.url_for(:ara_glacier)

  p Person.paginate(per: 2, page: 1)
  p Person.name

  p Person.prefix
  p ara.id
  p ara.first_name

end
