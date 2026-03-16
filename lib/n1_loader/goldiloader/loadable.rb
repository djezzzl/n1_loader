# frozen_string_literal: true

module N1Loader
  module Goldiloader
    # Extension to N1Loader::Loadable to integrate with Goldiloader.
    module Loadable
      def n1_loader(name)
        return n1_loaders[name] if n1_loaders[name]

        if respond_to?(:auto_include_context)
          context_setup = lambda { |records|
            ar_records = records.flatten(1).select { |r| r.respond_to?(:auto_include_context=) }
            ::Goldiloader::AutoIncludeContext.register_models(ar_records) if ar_records.any?
          }

          N1Loader::Preloader.new(auto_include_context.models, context_setup).preload(name)
        end

        super
      end
    end
  end
end
