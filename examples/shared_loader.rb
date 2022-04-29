require 'n1_loader'

# 3rd party service, or database, or anything else that can perform in batches
class Service
  def self.count
    @count ||= 0
  end

  def self.increase!
    @count = (@count || 0) + 1
  end

  def self.receive(*users)
    increase!

    users.flatten.map(&:object_id)
  end
end

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