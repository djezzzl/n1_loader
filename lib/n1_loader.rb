# frozen_string_literal: true

require_relative "n1_loader/version"

require_relative "n1_loader/core/name"
require_relative "n1_loader/core/loader"
require_relative "n1_loader/core/loader_collection"
require_relative "n1_loader/core/loadable"
require_relative "n1_loader/core/preloader"

module N1Loader # :nodoc:
  class Error < StandardError; end
  class NotImplemented < Error; end
  class NotLoaded < Error; end
  class NotFilled < Error; end
  class MissingArgument < Error; end
  class InvalidArgument < Error; end
end
