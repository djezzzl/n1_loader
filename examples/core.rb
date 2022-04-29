# frozen_string_literal: true

require "n1_loader"

require_relative 'context/service'

# Class that wants to request 3rd party service without N+1
class User
  include N1Loader::Loadable

  def unoptimized_call
    Service.receive(self)[0]
  end

  n1_optimized :optimized_call do |users|
    data = Service.receive(users)

    users.each_with_index do |user, index|
      fulfill(user, data[index])
    end
  end
end

# works fine for single case
user = User.new
p "Works correctly: #{user.unoptimized_call == user.optimized_call}"

users = [User.new, User.new]

# Has N+1
count_before = Service.count
p users.map(&:unoptimized_call)
p "Has N+1 #{Service.count == count_before + users.count}"

# Has no N+1
count_before = Service.count
N1Loader::Preloader.new(users).preload(:optimized_call)
p users.map(&:optimized_call)
p "Has no N+1: #{Service.count == count_before + 1}"
