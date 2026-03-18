# frozen_string_literal: true

# Load core library
require_relative "active_record"

# Load integration dependency
require "goldiloader"

# Library integration
require_relative "goldiloader/loadable"
require_relative "goldiloader/context_adapter"
require_relative "goldiloader/loader_collection_patch"
require_relative "goldiloader/preloader_patch"
require_relative "goldiloader/loader_patch"
require_relative "goldiloader/loader"
require_relative "goldiloader/context"

N1Loader::Loadable.prepend(N1Loader::Goldiloader::Loadable)
N1Loader::Preloader.prepend(N1Loader::Goldiloader::PreloaderPatch)
N1Loader::Loader.prepend(N1Loader::Goldiloader::LoaderPatch)
N1Loader::LoaderCollection.prepend(N1Loader::Goldiloader::LoaderCollectionPatch)
