# frozen_string_literal: true

module N1Loader
  module ArLazyPreload
    module Loadable
      module ClassMethods # :nodoc:
        def n1_load(name, loader = nil, &block)
          name, loader_name, loader_variable_name = super

          define_method(loader_name) do
            raise '1' # TODO: remove
            loader = instance_variable_get(loader_variable_name)

            return loader if loader
            if respond_to?(:lazy_preload_context) && ContextAdapter.new(lazy_preload_context).try_preload_lazily(name)
              return instance_variable_get(loader_variable_name)
            end

            instance_variable_set(loader_variable_name, self.class.send(loader_name).new([self]))
          end
        end
      end
    end
  end
end
