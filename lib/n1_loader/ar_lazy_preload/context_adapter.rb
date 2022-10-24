# frozen_string_literal: true

module N1Loader
  module ArLazyPreload
    # Context adapter for injected N1Loader loaders.
    class ContextAdapter
      attr_reader :context

      delegate_missing_to :context

      def initialize(context)
        @context = context
      end

      # Assign initialized preloader to +association_name+ in case it wasn't yet preloaded within the given context.
      def try_preload_lazily(association_name)
        return unless context&.send(:association_needs_preload?, association_name)

        perform_preloading(association_name)
      end

      # Initialize preloader for +association_name+ with context builder callback.
      # The callback will be executed when on records load.
      def perform_preloading(association_name)
        context_setup = lambda { |records|
          AssociatedContextBuilder.prepare(
            parent_context: self,
            association_name: association_name,
            records: records
          )
        }

        N1Loader::Preloader.new(records, context_setup).preload(association_name)
      end
    end
  end
end
