require 'n1_loader'

require_relative 'context/service'

# Loader that will be shared between multiple classes
class OptimizedLoader < N1Loader::Loader
  def perform(objects)
    data = Service.receive(objects)

    objects.each_with_index do |user, index|
      fulfill(user, data[index])
    end
  end

  def single(object)
    Service.single(object)
  end
end

class User
  include N1Loader::Loadable

  n1_optimized :optimized_call, OptimizedLoader
end

objects = [User.new, User.new]

N1Loader::Preloader.new(objects).preload(:optimized_call)

objects.map(&:optimized_call)
p "Used multi-case perform: #{Service.count == 1}"

User.new.optimized_call
p "Used single-case perform: #{Service.count == 1}"