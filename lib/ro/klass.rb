module Ro
  module Klass
    module ClassMethods
      def klass(arg, *args, **kws, &block)
        return arg if arg.is_a?(self.class) && args.empty? && kws.empty? && block.nil?

        new(arg, *args, **kws, &block)
      end

      alias for klass
    end

    module InstanceMethods
      def klass
        self.class
      end
    end

    def Klass.included(other)
      other.send(:extend, ClassMethods)
      other.send(:include, InstanceMethods)
      super
    end
  end
end
