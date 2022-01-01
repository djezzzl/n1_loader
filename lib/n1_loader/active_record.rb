# frozen_string_literal: true

# Load core library
require_relative "../n1_loader"

# Load integration dependency
require "active_record"

# Library integration
ActiveSupport.on_load(:active_record) do
  require_relative "active_record/loader"

  case ActiveRecord::VERSION::MAJOR
  when 6
    require_relative "active_record/associations_preloader_v6"
  else
    require_relative "active_record/associations_preloader_v5"
  end

  ActiveRecord::Associations::Preloader.prepend(N1Loader::ActiveRecord::Associations::Preloader)
end
