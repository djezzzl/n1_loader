# frozen_string_literal: true

require_relative "active_record"

require "rails"
require "ar_lazy_preload"

require_relative "ar_lazy_preload/loadable"
require_relative "ar_lazy_preload/context_adapter"
require_relative "ar_lazy_preload/associated_context_builder"

N1Loader::Loadable::ClassMethods.prepend(N1Loader::ArLazyPreload::Loadable::ClassMethods)
