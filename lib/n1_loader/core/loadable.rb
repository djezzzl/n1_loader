# frozen_string_literal: true

module N1Loader
  # The module to be included to the class to define associated loaders.
  #
  #   class Example
  #     include N1Loader::Loadable
  #
  #     # with inline loader
  #     n1_optimized :something do
  #       def perform(elements)
  #         elements.each { |element| fulfill(element, element.calculate_something) }
  #       end
  #     end
  #
  #     # with custom loader
  #     n1_optimized :something, MyLoader
  #   end
  #
  #   # custom loader
  #   class MyLoader < N1Loader::Loader
  #     def perform(elements)
  #       elements.each { |element| fulfill(element, element.calculate_something) }
  #     end
  #   end
  module Loadable
    def n1_loaders
      @n1_loaders ||= {}
    end

    def n1_loader(name)
      n1_loaders[name]
    end

    def n1_loader_reload(name)
      n1_loaders[name] = LoaderCollection.new(self.class.n1_loaders[name], [self])
    end

    def n1_clear_cache
      self.class.n1_loaders.each_key do |name|
        n1_loaders[name] = nil
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods # :nodoc:
      def n1_loaders
        @n1_loaders ||= superclass.respond_to?(:n1_loaders) ? superclass.n1_loaders.dup : {}
      end

      def n1_optimized(name, loader = nil, &block)
        loader ||= LoaderBuilder.build(&block)

        n1_loaders[name] = loader

        define_method(name) do |reload: false, **args|
          n1_loader_reload(name) if reload || n1_loader(name).nil?

          n1_loader(name).with(**args).for(self)
        end
      end
    end
  end
end
