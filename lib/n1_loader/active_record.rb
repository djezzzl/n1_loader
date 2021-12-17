# frozen_string_literal: true

require "active_record"

require_relative "active_record/associations_preloader"

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Associations::Preloader.prepend(N1Loader::ActiveRecord::Associations::Preloader)
end
