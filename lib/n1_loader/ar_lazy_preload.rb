# frozen_string_literal: true

# Load core library
require_relative "active_record"

# Load integration dependency
require "rails"
require "ar_lazy_preload"

# Library integration
require_relative "ar_lazy_preload/loadable"
require_relative "ar_lazy_preload/context_adapter"
require_relative "ar_lazy_preload/associated_context_builder"

N1Loader::Loadable::ClassMethods.prepend(N1Loader::ArLazyPreload::Loadable::ClassMethods)
