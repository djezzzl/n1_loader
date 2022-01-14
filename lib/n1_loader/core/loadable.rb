# frozen_string_literal: true

module N1Loader
  # The module to be included to the class to define associated loaders.
  #
  #   class Example
  #     include N1Loader::Loadable
  #
  #     # with inline loader
  #     n1_loader :something do
  #       def perform(elements)
  #         elements.each { |element| fulfill(element,, element.calculate_something) }
  #       end
  #     end
  #
  #     # with custom loader
  #     n1_loader :something, MyLoader
  #   end
  #
  #   # custom loader
  #   class MyLoader < N1Loader::Loader
  #     def perform(elements)
  #       elements.each { |element| fulfill(element,, element.calculate_something) }
  #     end
  #   end
  module Loadable
    def n1_loader(name)
      send("#{name}_loader")
    end

    def n1_loader_set(name, loader_collection)
      send("#{name}_loader=", loader_collection)
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods # :nodoc:
      def n1_loader(name)
        send("#{name}_loader")
      end

      def n1_loader_defined?(name)
        respond_to?("#{name}_loader")
      end

      def n1_load(name, loader = nil, &block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        loader ||= Class.new(N1Loader::Loader) do
          if block&.arity&.positive?
            define_method(:perform, &block)
          else
            class_eval(&block)
          end
        end
        loader_name = "#{name}_loader"
        loader_variable_name = "@#{loader_name}"

        define_singleton_method(loader_name) do
          loader
        end

        define_method("#{loader_name}_reload") do
          instance_variable_set(loader_variable_name,
                                N1Loader::LoaderCollection.new(self.class.send(loader_name), [self]))
        end

        define_method("#{loader_name}=") do |loader_collection_instance|
          instance_variable_set(loader_variable_name, loader_collection_instance)
        end

        define_method(loader_name) do
          instance_variable_get(loader_variable_name) || send("#{loader_name}_reload")
        end

        define_method(name) do |*args, reload: false|
          send("#{loader_name}_reload") if reload

          send(loader_name).with(*args).for(self)
        end

        [name, loader_name, loader_variable_name]
      end
    end
  end
end
