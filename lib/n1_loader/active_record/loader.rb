# frozen_string_literal: true

N1Loader::Loader.define_method :preloaded_records do
  @preloaded_records ||= loaded? && loaded_by_value.values.flatten
end
