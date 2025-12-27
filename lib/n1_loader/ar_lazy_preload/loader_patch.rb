# frozen_string_literal: true

module N1Loader
  module ArLazyPreload
    # A patch to {N1Loader::Loader} to setup lazy context lazily.
    module LoaderPatch
      attr_accessor :context_setup

      def loaded
        return @loaded if @already_loaded && @already_context

        super

        synchronize do
          context_setup&.call(@loaded.values.flatten) unless @already_context
        end

        @already_context = true
        @loaded
      end
    end
  end
end
