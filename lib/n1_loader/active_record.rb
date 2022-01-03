# frozen_string_literal: true

# Load core library
require_relative "../n1_loader"

# Load integration dependency
require "active_record"

module N1Loader
  module ActiveRecord
    class InvalidPreloading < N1Loader::Error; end
  end
end

# Library integration
ActiveSupport.on_load(:active_record) do
  require_relative "active_record/loader"
  require_relative "active_record/loader_collection"

  case ActiveRecord::VERSION::MAJOR
  when 6
    require_relative "active_record/associations_preloader_v6"
  else
    require_relative "active_record/associations_preloader_v5"
  end

  ActiveRecord::Associations::Preloader.prepend(N1Loader::ActiveRecord::Associations::Preloader)
end
