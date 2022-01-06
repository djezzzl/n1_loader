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
require_relative "ar_lazy_preload/loader_collection_patch"
require_relative "ar_lazy_preload/preloader"
require_relative 'ar_lazy_preload/loader_patch'

N1Loader::Loadable::ClassMethods.prepend(N1Loader::ArLazyPreload::Loadable::ClassMethods)
N1Loader::Loader.prepend(N1Loader::ArLazyPreload::LoaderPatch)
N1Loader::LoaderCollection.prepend(N1Loader::ArLazyPreload::LoaderCollectionPatch)
