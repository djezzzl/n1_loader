# frozen_string_literal: true

module N1Loader
  module Goldiloader
    # A patch to {N1Loader::Loader} to setup lazy context lazily.
    module LoaderPatch
      attr_accessor :context_setup

      def loaded
        return @loaded_by_identity if @already_loaded && @already_context

        super

        synchronize do
          context_setup&.call(@loaded_by_identity.values.flatten) unless @already_context
        end

        @already_context = true
        @loaded_by_identity
      end
    end
  end
end
