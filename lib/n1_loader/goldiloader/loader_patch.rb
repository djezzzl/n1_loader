# frozen_string_literal: true

module N1Loader
  module Goldiloader
    # A patch to {N1Loader::Loader} to setup lazy context lazily.
    module LoaderPatch
      attr_accessor :context_setup

      def loaded?
        return true if @already_loaded && @already_context

        super

        synchronize { non_thread_safe_context_setting unless @already_context }

        true
      end

      def non_thread_safe_context_setting
        return if @already_context

        context_setup&.call(loaded_by_identity.values.flatten)

        @already_context = true
      end
    end
  end
end
