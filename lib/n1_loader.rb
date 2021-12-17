# frozen_string_literal: true

require_relative "n1_loader/version"

require_relative "n1_loader/loader"
require_relative "n1_loader/loadable"
require_relative "n1_loader/preloader"

module N1Loader # :nodoc:
  class Error < StandardError; end
  class NotImplemented < Error; end
  class NotLoaded < Error; end
end
