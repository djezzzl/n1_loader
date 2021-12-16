# frozen_string_literal: true

module N1Loader
  module Loadable
    def n1_loader(name)
      send("#{name}_loader")
    end

    def n1_loader_set(name, loader)
      send("#{name}_loader=", loader)
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def n1_loader(name)
        send("#{name}_loader")
      end

      def n1_load(name, loader = nil, &block)
        loader ||= Class.new(N1Loader::Loader) do
          define_method(:perform, &block)
        end

        loader_name = "#{name}_loader"
        loader_variable_name = "@#{loader_name}"

        define_singleton_method(loader_name) do
          loader
        end

        define_method("#{loader_name}=") do |loader_instance|
          instance_variable_set(loader_variable_name, loader_instance)
        end

        define_method(loader_name) do
          instance_variable_get(loader_variable_name) ||
            instance_variable_set(loader_variable_name, self.class.send(loader_name).new([self]))
        end

        define_method(name) do
          send(loader_name).for(self)
        end
      end
    end
  end
end
