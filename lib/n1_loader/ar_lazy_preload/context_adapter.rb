# frozen_string_literal: true

module N1Loader
  module ArLazyPreload
    # Context adapter for N1Loader
    class ContextAdapter
      attr_reader :context

      delegate_missing_to :context

      def initialize(context)
        @context = context
      end

      def try_preload_lazily(association_name)
        return unless context&.send(:association_needs_preload?, association_name)

        perform_preloading(association_name)
      end

      def perform_preloading(association_name)
        N1Loader::Preloader.new(records).preload(association_name)

        AssociatedContextBuilder.prepare(
          parent_context: self,
          association_name: association_name
        )
      end
    end
  end
end
