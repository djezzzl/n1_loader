require 'n1_loader'

require_relative 'context/service'

# Loader that will be shared between multiple classes
class SharedLoader < N1Loader::Loader
  def perform(objects)
    data = Service.receive(objects)

    objects.each_with_index do |user, index|
      fulfill(user, data[index])
    end
  end
end

class User
  include N1Loader::Loadable

  n1_optimized :optimized_call, SharedLoader
end

class Payment
  include N1Loader::Loadable

  n1_optimized :optimized_call, SharedLoader
end

objects = [User.new, Payment.new, User.new, Payment.new]

N1Loader::Preloader.new(objects).preload(:optimized_call)

# First time loading for all objects
objects.map(&:optimized_call)
p "Loaded for all once: #{Service.count == 1}"