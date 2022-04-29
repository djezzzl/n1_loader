require 'n1_loader'

require_relative 'context/service'

class User
  include N1Loader::Loadable

  n1_optimized :optimized_call do |users|
    data = Service.receive(users)

    users.each_with_index do |user, index|
      fulfill(user, data[index])
    end
  end
end

users = [User.new, User.new, User.new]

# Initialized loader but didn't perform it yet
N1Loader::Preloader.new(users).preload(:optimized_call)
p "No calls yet: #{Service.count == 0}"

# First time loading
users.map(&:optimized_call)
p "First time loaded: #{Service.count == 1}"

users.first.optimized_call(reload: true)
p "Reloaded for this object only: #{Service.count == 2}"

users.first.n1_clear_cache
users.first.optimized_call
p "Reloaded for this object only: #{Service.count == 3}"