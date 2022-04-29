# frozen_string_literal: true

module N1Loader
  module ActiveRecord
    # Extension module for ActiveRecord::Base
    module Base
      include N1Loader::Loadable

      # Clear N1Loader cache on reloading the object
      def reload(*)
        n1_clear_cache
        super
      end
    end
  end
end
