# frozen_string_literal: true

require_relative "../n1_loader"

require "active_record"

ActiveSupport.on_load(:active_record) do
  if ActiveRecord::VERSION::MAJOR < 6
    require_relative "active_record/associations_preloader_v5"
  else
    require_relative "active_record/associations_preloader"
  end
  ActiveRecord::Associations::Preloader.prepend(N1Loader::ActiveRecord::Associations::Preloader)
end
