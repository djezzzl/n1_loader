# frozen_string_literal: true

require_relative "../n1_loader"
require_relative "active_record/loader"
require "active_record"

ActiveSupport.on_load(:active_record) do
  case ActiveRecord::VERSION::MAJOR
  when 6
    require_relative "active_record/associations_preloader_v6"
  else
    require_relative "active_record/associations_preloader_v5"
  end

  ActiveRecord::Associations::Preloader.prepend(N1Loader::ActiveRecord::Associations::Preloader)
end
