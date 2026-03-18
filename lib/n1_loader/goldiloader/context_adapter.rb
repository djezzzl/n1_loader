# frozen_string_literal: true

module N1Loader
  module Goldiloader
    # Context adapter for injected N1Loader loaders.
    class ContextAdapter
      attr_reader :context

      def initialize(context)
        @context = context
      end

      # Trigger preloading for +association_name+ across all models in the context.
      def try_preload_lazily(association_name)
        perform_preloading(association_name) if context
      end

      # Initialize preloader for +association_name+ with context builder callback.
      # The callback will be executed when records are loaded.
      def perform_preloading(association_name)
        context_setup = lambda { |records|
          ar_records = records.flatten(1).select { |record| record.respond_to?(:auto_include_context=) }
          ::Goldiloader::AutoIncludeContext.register_models(ar_records) unless ar_records.empty?
        }

        N1Loader::Preloader.new(context.models, context_setup).preload(association_name)
      end
    end
  end
end
